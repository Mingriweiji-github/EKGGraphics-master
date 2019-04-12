//
//  ViewController.m
//  EKGGraphics-master
//
//  Created by Seven on 2019/4/4.
//  Copyright © 2019年 LuoKeRen. All rights reserved.
//

#import "ViewController.h"
#import "HeartGraphicsView.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic, strong) HeartGraphicsView *refreshMoniterView;

@property (nonatomic, strong) NSMutableArray *mArr;
@property (nonatomic , strong) NSArray *dataSource;

@property (nonatomic , strong) CBCentralManager *ctrlManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCharacteristic *characteristic;

@property (nonatomic, strong) NSMutableDictionary *deviceDic;
@property (nonatomic, strong) NSMutableArray *peripherals;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.refreshMoniterView];
    self.title = @"心电图";
    self.view.backgroundColor = [UIColor blackColor];
#if TARGET_IPHONE_SIMULATOR
    [self readData];//测试数据
#define SIMULATOR_TEST
#else
    self.ctrlManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];    //蓝牙数据
#endif
    
    [self createWorkDataSourceWithTimeInterval:0.01];

}
#pragma mark - CBCentralManagerDelegate
/**
 1.扫描外设
 @param central CBCentralManager
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@"unknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"resetting");
        case CBCentralManagerStateUnsupported:
            NSLog(@"unSupported");
        case CBCentralManagerStateUnauthorized:
            NSLog(@"unAuthorized");
        case CBCentralManagerStatePoweredOn:
        {
             NSLog(@"powerdOn");
            [self.ctrlManager scanForPeripheralsWithServices:nil options:nil];
        }
        case CBCentralManagerStatePoweredOff:
            NSLog(@"poweredOff");
        default:
            break;
    }
}
/**
 2.发现外设
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"发现外设:%@",[peripheral name]);
    if ([peripheral.name hasPrefix:@"AD"]) {
        //持有外设，否则CBCentralManager中不会保存peripheral,CBPeripheralDelegate中的方法也不会被调用
        [self.peripherals addObject:peripheral];
        //连接外设
        [self.ctrlManager connectPeripheral:peripheral options:nil];
    }
}
- (NSMutableArray *)peripherals {
    if (_peripherals == nil) {
        _peripherals = [NSMutableArray array];
    }
    return _peripherals;
}
/**
 3.成功连接外设
 @param central CBCentralManager
 @param peripheral CBPeripheral
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@">>>连接到名称为（%@）的设备-成功",peripheral.name);
    if ([peripheral.name isEqualToString:@"AD8233"]) {
        [self.ctrlManager stopScan];//连接成功后 停止扫描 节省内存
    }
    peripheral.delegate = self;//设置peripheral 的代理方法CBPeripheralDelegate
    self.peripheral = peripheral;
    //扫描外设Services，成功后会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    [peripheral discoverServices:nil];
}
/**
 连接外设失败
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@">>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]);
}
/**
 取消与外设连接回调
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"取消了回调=%@",peripheral);
}

#pragma mark - CBPeripheralDelegate
/**
 4.获取外设服务
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (error)
    {
        NSLog(@">>>Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    CBService *__nullable findService = nil;
    for (CBService *service in peripheral.services) {
        if ([[service UUID] isEqual:[CBUUID UUIDWithString:@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"]]) {
            findService = service;
        }
    }
    // characteristicUUIDs : 可以指定想要扫描的特征(传nil,扫描所有的特征)
    if (findService) {
        [peripheral discoverCharacteristics:NULL forService:findService];
    }
}
/**
 5.0 获取外设服务特征回调
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        if ([characteristic.UUID.UUIDString isEqualToString:@"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"]) {
            // 拿到某个特征,和外围设备进行交互
            [self notifyCharacteristic:peripheral characteristic:characteristic];
        }
    }
    for (CBCharacteristic *characteristic in service.characteristics){
        {// 拿到特征,和外围设备进行交互
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
}
//搜索到Characteristic的Descriptors
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    for (CBDescriptor *d in characteristic.descriptors) {
        NSLog(@"Descriptor uuid:%@",d.UUID);
    }
}
//获取到Descriptors的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    //打印出DescriptorsUUID 和value
    //这个descriptor都是对于characteristic的描述，一般都是字符串，所以这里我们转换成字符串去解析
    NSLog(@"characteristic uuid:%@  value:%@",[NSString stringWithFormat:@"%@",descriptor.UUID],descriptor.value);
}

/**
 从外设服务特征实时读取数据
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (characteristic.isNotifying) {
        [peripheral readValueForCharacteristic:characteristic];
    }else{
        NSLog(@"Noti stopped on %@",characteristic);
        [self.ctrlManager cancelPeripheralConnection:peripheral];
    }
}
//写数据
-(void)writeCharacteristic:(CBPeripheral *)peripheral
            characteristic:(CBCharacteristic *)characteristic
                     value:(NSData *)value{
    
    NSLog(@"%lu", (unsigned long)characteristic.properties);
    //只有 characteristic.properties 有write的权限才可以写
    if(characteristic.properties & CBCharacteristicPropertyWrite){
        /*
         最好一个type参数可以为CBCharacteristicWriteWithResponse或type:CBCharacteristicWriteWithResponse,区别是是否会有反馈
         */
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }else{
        NSLog(@"该字段不可写！");
    }
}
//设置peripheral通知
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic{
    //设置通知，数据通知会进入：didUpdateValueForCharacteristic方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    [self.ctrlManager stopScan];
}
//取消通知
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                   characteristic:(CBCharacteristic *)characteristic{
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}
//停止扫描并断开连接
-(void)disconnectPeripheral:(CBCentralManager *)centralManager
                 peripheral:(CBPeripheral *)peripheral{
    //停止扫描
    [centralManager stopScan];
    //断开连接
    [centralManager cancelPeripheralConnection:peripheral];
}
#pragma mark - 获取的外设特征的value值
/**
 注意: value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
 value: <aaaa01a0 000d000a 000b000a 000b000b 000a000b 000c000c 0009000c 0007000c 000a000d 0009000c 000a000d 000a000c 000d000c 000d000b 000a000a 000e000a 000b000d 000c000b 000a000b 0007000b 000c000c 000c000b 000c000b 000d000b 000a000b 000a000b 000d000b 000e000b 000e000b 000a000a 000d000b 000c000b 000b000b 000b000d 000c0009 000b000b 000e000a 000d0009 000d>
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"characteristic uuid:%@  value:%@",characteristic.UUID,characteristic.value);
    if ([characteristic.UUID.UUIDString isEqualToString:@"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"]) {
        NSString *content = [NSString stringWithFormat:@"%@",characteristic.value];
        NSString *temp = [content stringByReplacingOccurrencesOfString:@" " withString:@""];
        temp = [temp substringFromIndex:1];
        temp = [temp substringToIndex:temp.length - 1];
        if (temp.length == 308) {
            NSString *lbeString = [temp substringWithRange:NSMakeRange(8, 300)];//前8位的16进制数设备信息不处理
            NSArray *tempData = [self praseHexWithContentString:lbeString withRatio:3];
            NSLog(@"tempArr = %@",tempData);
            [self.mArr addObjectsFromArray:tempData];
            self.dataSource = self.mArr;
        }else{
            NSAssert(temp.length != 308, @"接受到数据但是非标准长度");
        }
    }
}

#pragma mark - 测试数据

- (void)readData {
    NSError *error;
    NSString *text = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LBEData" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error];
    NSString *current = [text stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    [current enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        if ([line hasPrefix:@"AAAA"]) {
            @autoreleasepool {
                NSString *lbeString = [line substringWithRange:NSMakeRange(8, 300)];//前8位-2个16进制数对应设备信息不处理
                [lbeString enumerateSubstringsInRange:NSMakeRange(0, lbeString.length) options:NSStringEnumerationByWords usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
                    NSArray *tempData = [self praseHexWithContentString:substring withRatio:3];
                    NSLog(@"tempData=%@",tempData);
                    [self.mArr addObjectsFromArray:tempData];
                }];
                
            }
        }
    }];
    
    NSLog(@"mArr.count=%lu",(unsigned long)self.mArr.count);
    self.dataSource = self.mArr;
    
}
- (void)createWorkDataSourceWithTimeInterval:(NSTimeInterval )timeInterval{
    [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(timerRefresnFun) userInfo:nil repeats:YES];
}
//刷新方式绘制
- (void)timerRefresnFun{
    //坐标点
    CGPoint point = [self bubbleRefreshPoint];
    [[PointContainer sharedInstance] addPointAsRefreshChangeForm:point];
    //绘图点坐标
    CGPoint *curePoint = [PointContainer sharedInstance].refreshPointContainer;
    NSInteger numberOfRreshElements = [PointContainer sharedInstance].numberOfRreshElements;
    [self.refreshMoniterView drawWithPoints:curePoint WithCount:numberOfRreshElements];
}

/**
 数据处理
 */
- (CGPoint)bubbleRefreshPoint{
    static NSInteger dataSourceCounterIndex = -1;
    dataSourceCounterIndex ++ ;
    dataSourceCounterIndex %= [self.dataSource count];
    NSInteger pixelPerPoint = 1;
    static NSInteger xCoordinateInMoniter = 0;
    //todo:动态
    CGFloat point_y = [self.dataSource[dataSourceCounterIndex] integerValue] * 0.5 + 120;
    CGPoint targetPointToAdd = (CGPoint){xCoordinateInMoniter,point_y};
    xCoordinateInMoniter += pixelPerPoint;
    xCoordinateInMoniter %= (int)(CGRectGetWidth(self.refreshMoniterView.frame));
    return targetPointToAdd;
}

/**
 第一步：16进制转NSData
 */
- (NSData *)dataFromHexString:(NSString *)hexString{
    const char * chars = [hexString UTF8String];
    int i = 0;
    NSUInteger len = hexString.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteCharts[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteCharts[0] = chars[i++];
        byteCharts[1] = chars[i++];
        wholeByte = strtoul(byteCharts, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    return data;
}
/**
 第二步：2进制转int
 */
- (unsigned)parseIntFromData:(NSData *)data{
    NSString *dataDescription = [data description];
    NSString *dataString = [dataDescription substringWithRange:NSMakeRange(1, [dataDescription length] - 2)];
    
    unsigned intData = 0;
    NSScanner *scanner = [NSScanner scannerWithString:dataString];
    [scanner scanHexInt:&intData];
    return intData;
}
/**
 第三步：int ->short
 @param string HexString
 @return short 数组
 */
- (NSArray *)praseHexWithContentString:(NSString *)string withRatio:(int)ratio{
    NSString *tempString = string;
    NSInteger size = tempString.length / 4;
    NSMutableArray *tempArr = [NSMutableArray array];
    for (int n = 0; n < size; n++) {
        NSString *hexString = [tempString substringWithRange:NSMakeRange(n * 4, 4)];
        NSData *tempData = [self dataFromHexString:hexString];
        unsigned num = [self parseIntFromData:tempData];
        //int ->short
        short shortNum = ((short)num) / ratio;
        
        [tempArr addObject:[NSString stringWithFormat:@"%d",shortNum]];
    }
    return tempArr;
}
#pragma mark - setter & getter
- (NSMutableArray *)mArr {
    if (_mArr == nil) {
        _mArr = [NSMutableArray array];
    }
    return _mArr;
}
- (HeartGraphicsView *)refreshMoniterView
{
    if (!_refreshMoniterView) {
        CGFloat xOffset = 10;
        _refreshMoniterView = [[HeartGraphicsView alloc] initWithFrame:CGRectMake(xOffset, 120, CGRectGetWidth(self.view.frame)  - xOffset * 2 - 20, 200)];
        _refreshMoniterView.backgroundColor = [UIColor blackColor];
    }
    return _refreshMoniterView;
}
@end
