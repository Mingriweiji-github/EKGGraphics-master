//
//  ViewController.m
//  EKGGraphics-master
//
//  Created by Seven on 2019/4/4.
//  Copyright © 2019年 LuoKeRen. All rights reserved.
//

#import "ViewController.h"
#import "HeartGraphicsView.h"
@interface ViewController ()
@property (nonatomic, strong) HeartGraphicsView *refreshMoniterView;

@property (nonatomic, strong) NSMutableArray *mArr;
@property (nonatomic , strong) NSArray *dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.refreshMoniterView];
    self.title = @"心电图";
    self.view.backgroundColor = [UIColor blackColor];
    
    [self readData];
}
- (void)createWorkDataSourceWithTimeInterval:(NSTimeInterval )timeInterval
{
    [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(timerRefresnFun) userInfo:nil repeats:YES];
    
}
//刷新方式绘制
- (void)timerRefresnFun{
    //grid
    CGPoint point = [self bubbleRefreshPoint];
    [[PointContainer sharedInstance] addPointAsRefreshChangeForm:point];
    //curve
    CGPoint *refreshPoint = [PointContainer sharedInstance].refreshPointContainer;
    NSInteger numberOfRreshElements = [PointContainer sharedInstance].numberOfRreshElements;
    [self.refreshMoniterView drawWithPoints:refreshPoint WithCount:numberOfRreshElements];
}

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
- (void)readData {
    NSError *error;
    NSString *text = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LBEData" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error];
    NSString *current = [text stringByReplacingOccurrencesOfString:@"-" withString:@""];

    [current enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        if ([line hasPrefix:@"AAAA"]) {
            @autoreleasepool {
                NSString *lbeString = [line substringWithRange:NSMakeRange(8, 300)];//前8位-2个16进制数对应设备信息不处理
                [lbeString enumerateSubstringsInRange:NSMakeRange(0, lbeString.length) options:NSStringEnumerationByWords usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
                    NSArray *tempData = [self insertWhiteSpaceWithNum:substring];
                    NSLog(@"tempData=%@",tempData);
                    [self.mArr addObjectsFromArray:tempData];
                }];

            }
        }
    }];

    NSLog(@"mArr.count=%ld",self.mArr.count);
    self.dataSource = self.mArr;
    [self createWorkDataSourceWithTimeInterval:0.025];

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
-(NSArray *)insertWhiteSpaceWithNum:(NSString *)string{
    NSString *tempString = string;
    NSInteger size = tempString.length / 4;
    NSMutableArray *tempArr = [NSMutableArray array];
    for (int n = 0; n < size; n++) {
        NSString *hexString = [tempString substringWithRange:NSMakeRange(n * 4, 4)];
        NSData *tempData = [self dataFromHexString:hexString];
        unsigned num = [self parseIntFromData:tempData];
        //int ->short
        short shortNum = ((short)num) / 3;
        
        [tempArr addObject:[NSString stringWithFormat:@"%d",shortNum]];
    }
    return tempArr;
}
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
        _refreshMoniterView = [[HeartGraphicsView alloc] initWithFrame:CGRectMake(xOffset, 120, CGRectGetWidth(self.view.frame) / 2 - xOffset, 200)];
        _refreshMoniterView.backgroundColor = [UIColor blackColor];
    }
    return _refreshMoniterView;
}
@end
