//
//  HeartGraphicsView.m
//  EKGGraphics-master
//
//  Created by Seven on 2019/4/4.
//  Copyright © 2019年 LuoKeRen. All rights reserved.
//

#import "HeartGraphicsView.h"

static const double kScale = 0.5;
static const NSInteger kMaxContainCapacity = 360;

@interface PointContainer()
@property (nonatomic, assign) NSInteger numberOfRreshElements;
@property (nonatomic, assign) CGPoint* refreshPointContainer;
@end
@implementation PointContainer
+ (PointContainer *)sharedInstance{
    static PointContainer *container = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        container = [[self alloc] init];
        NSLog(@"The size of a CGPoint is %lu", sizeof(double));
        container.refreshPointContainer = malloc(sizeof(CGPoint) * kMaxContainCapacity);
        //初始化refreshPointContainer 默认值全部设置为0
        memset(container.refreshPointContainer, 0, sizeof(CGPoint) * kMaxContainCapacity);
    });
    return container;
}
- (void)dealloc
{
    free(self.refreshPointContainer);
    self.refreshPointContainer = NULL;
}
- (void)addPointAsRefreshChangeForm:(CGPoint)point {
    static NSInteger currentPointsCount = 0;
    if (currentPointsCount < kMaxContainCapacity) {
        self.numberOfRreshElements = currentPointsCount + 1;
        self.refreshPointContainer[currentPointsCount] = point;
        currentPointsCount ++ ;
    }else {
        NSInteger workIndex = 0;
        while (workIndex != kMaxContainCapacity - 1) {
            self.refreshPointContainer[workIndex] = self.refreshPointContainer[workIndex + 1];
            workIndex ++ ;
        }
        self.refreshPointContainer[kMaxContainCapacity -1] = point;
        self.numberOfRreshElements = kMaxContainCapacity;
    }
}
@end

@interface HeartGraphicsView()
@property (nonatomic, assign) NSInteger currentPointsCount;
@property (nonatomic, assign) CGPoint *points;
@property (nonatomic, assign) NSInteger full_width;
@property (nonatomic, assign) NSInteger full_height;
@property (nonatomic, assign) CGFloat cell_square_width;

@end
@implementation HeartGraphicsView
- (void)setPoints:(CGPoint *)points {
    _points = points;
    [self setNeedsDisplay];//调用drawRect更新数据
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clearsContextBeforeDrawing = YES;//默认YES
    }
    return self;
}
- (void)drawWithPoints:(CGPoint *)points WithCount:(NSInteger)count{
    self.currentPointsCount = count;
    self.points = points;
}
- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    [self drawGrid];
    [self drawCurveLine];
}

/**
 心电图绘制
 */
- (void)drawCurveLine {
    if (self.currentPointsCount == 0) {
        return;
    }
    CGFloat curveLineWidth = 0.8;
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(currentContext, curveLineWidth);
    CGContextSetStrokeColorWithColor(currentContext, [UIColor greenColor].CGColor);
    
    //开始绘制
    NSLog(@"开始：%@",NSStringFromCGPoint(*(self.points)));
    CGContextMoveToPoint(currentContext, self.points[0].x, self.points[0].y);
    for (int i = 1; i <= self.currentPointsCount * kScale; ++i) {//scale
        if (self.points[i-1].x < self.points[i].x) {
//            NSLog(@"Pi-1=%@, Pi=%@",NSStringFromCGPoint(self.points[i-1]),NSStringFromCGPoint(self.points[i]));
            CGContextAddLineToPoint(currentContext, self.points[i].x, self.points[i].y);
        }else{//重新绘制坐标
            CGContextMoveToPoint(currentContext, self.points[i].x, self.points[i].y);
        }
    }
    CGContextStrokePath(currentContext);
}

/**
 坐标轴绘制
 */
- (void)drawGrid {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, 0.5f);
    CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
    //todo:text
    self.full_width = self.frame.size.width;
    self.full_height = self.frame.size.height;
    
    self.cell_square_width = 30 * kScale;//默认1大格子对应的物理像素 Scale
    
    CGFloat pos_x = 1;
    while (pos_x < self.full_width) {//所有的Y轴
        CGContextMoveToPoint(ctx, pos_x, 1);
        CGContextAddLineToPoint(ctx, pos_x, self.full_height);
        pos_x += _cell_square_width;
        CGContextStrokePath(ctx);
    }
    
    CGFloat pos_y = 1;
    while (pos_y < self.full_height) {//所有的X轴
        CGContextSetLineWidth(ctx, 1);
        CGContextMoveToPoint(ctx, 1, pos_y);
        CGContextAddLineToPoint(ctx, self.full_width, pos_y);
        pos_y += _cell_square_width;
        CGContextStrokePath(ctx);
    }
    
    CGContextSetLineWidth(ctx, 0.5);
    _cell_square_width = _cell_square_width / 5;
    pos_x = 1 + _cell_square_width;
    while (pos_x < _full_width) {
        CGContextMoveToPoint(ctx, pos_x, 1);
        CGContextAddLineToPoint(ctx, pos_x, _full_height);
        pos_x += _cell_square_width;
        CGContextStrokePath(ctx);
    }
    pos_y = 1 + _cell_square_width;
    while (pos_y <= _full_height) {
        CGContextMoveToPoint(ctx, 1, pos_y);
        CGContextAddLineToPoint(ctx, _full_width, pos_y);
        pos_y += _cell_square_width;
        CGContextStrokePath(ctx);
    }
    
}
@end
