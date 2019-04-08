//
//  HeartGraphicsView.h
//  EKGGraphics-master
//
//  Created by Seven on 2019/4/4.
//  Copyright © 2019年 LuoKeRen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface PointContainer : NSObject
@property (nonatomic, assign, readonly) NSInteger numberOfRreshElements;
@property (nonatomic, assign, readonly) CGPoint* refreshPointContainer;

+ (PointContainer *)sharedInstance;
- (void)addPointAsRefreshChangeForm:(CGPoint)point;

@end

@interface HeartGraphicsView : UIView
- (void)drawWithPoints:(CGPoint *)points WithCount:(NSInteger)count;
@end

NS_ASSUME_NONNULL_END
