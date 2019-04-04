//
//  HeartGraphicsView.m
//  EKGGraphics-master
//
//  Created by Seven on 2019/4/4.
//  Copyright © 2019年 LuoKeRen. All rights reserved.
//

#import "HeartGraphicsView.h"

static const NSInteger kMaxContainCapacity = 300;
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
@property (nonatomic, assign) CGPoint points;
@property (nonatomic, assign) NSInteger full_width;
@property (nonatomic, assign) NSInteger full_height;
@property (nonatomic, assign) NSInteger cell_square_width;

@end
@implementation HeartGraphicsView
- (void)setPoints:(CGPoint)points {
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
- (void)drawWithPoints:(CGPoint)points WithCount:(NSInteger)count{
    self.currentPointsCount = count;
    self.points = points;
}
- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    [self drawGrid];
}
- (void)drawGrid {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, 0.2);
    CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
    //todo:text
    self.full_width = self.frame.size.width;
    self.full_height = self.frame.size.height;
    self.cell_square_width = 30;
    
    int pos_x = 1;
    while (pos_x < _full_width) {//所有的Y轴
        CGContextMoveToPoint(ctx, pos_x, 1);
        CGContextAddLineToPoint(ctx, pos_x, _full_height);
        pos_x += _cell_square_width;
        CGContextStrokePath(ctx);
    }
    
}
@end
