
//
//  WSMAMapView.m
//  CommentFrame
//
//  Created by 王帅 on 12/10/18.
//  Copyright © 2018 warron. All rights reserved.
//

#import "WSMAMapView.h"

typedef enum MapBoderSides{
    BorderLeft = 100,
    BorderTop,
    BorderRight,
    BorderBottom,
    
    BorderLeftTop,
    BorderLeftRight,
    BorderLeftBottom,
    
    BorderTopRight,
    BorderTopBottom,
    
    BorderRightBottom,
    
    BorderLeftTopRight,
    BorderLeftTopBottom,
    BorderLeftRightBottom,
    
    BorderAll
}MapBoderSides;
typedef enum MoveDirection{
    MoveLeft = 100,
    MoveTop,
    MoveRight,
    MoveBottom,
    MoveLeftBottom,
    MoveLeftTop,
    MoveRightBottom,
    MoveRightTop
}MoveDirection;
@interface WSMAMapView ()<UIGestureRecognizerDelegate>

@property (strong, nonatomic)UIPanGestureRecognizer *panMove;//手动添加的手势
@property (strong, nonatomic)UIPanGestureRecognizer *panMap;//地图自带的 拖动手势
@property (assign, nonatomic)MoveDirection moveDirection;
@property (assign, nonatomic)MapBoderSides mapBoderSides;
@end
@implementation WSMAMapView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _panMap = self.gestureRecognizers[4];
    }
    return self;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    [self commitTranslation:gestureRecognizer];
    if ([self isMoveMapView]) {
        [_panMap addTarget:self action:@selector(handlePan:)];
        [_panMap removeTarget:self action:@selector(panGesture:)];
    }else{
        [_panMap addTarget:self action:@selector(panGesture:)];
        [_panMap removeTarget:self action:@selector(handlePan:)];
        return YES;
    }
    _moveDirection = 0;
    return YES;
}

// 询问delegate，两个手势是否同时接收消息，返回YES同事接收。返回NO，不同是接收（如果另外一个手势返回YES，则并不能保证不同时接收消息
// 这个函数一般在一个手势接收者要阻止另外一个手势接收自己的消息的时候调用
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if (gestureRecognizer == _panMap) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return NO;
}

// 询问delegate是否允许手势接收者接收一个touch对象
// 返回YES，则允许对这个touch对象审核，NO，则不允许。
// 这个方法在touchesBegan:withEvent:之前调用，为一个新的touch对象进行调用
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([gestureRecognizer  isKindOfClass:[UITapGestureRecognizer class]]) {
        CGFloat width = CGRectGetWidth(self.frame);
        CGFloat height = CGRectGetHeight(self.frame);
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.frame = CGRectMake(0, 0, width,height);
        } completion:^(BOOL finished) {
            [_panMap addTarget:self action:@selector(panGesture:)];
        }];
    }
    if ([gestureRecognizer isKindOfClass:NSClassFromString(@"UIRotationGestureRecognizer")]) {
        [gestureRecognizer removeTarget:self action:@selector(rotateGesture:)];//移除旋转手势
        return NO;
    }
    if ([gestureRecognizer isKindOfClass:NSClassFromString(@"UIPanGestureRecognizer")]) {
        SEL s = @selector(pullGesture:);
        if ([self respondsToSelector:s]) {//移除 相机角度的手势
            [gestureRecognizer removeTarget:self action:@selector(pullGesture:)];
        }
        return YES;
    }
    return YES;
}

- (void)handlePan:(UIPanGestureRecognizer*) recognizer{
  
    CGFloat minX = CGRectGetMinX(self.frame);
    CGFloat minY = CGRectGetMinY(self.frame);
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:[UIApplication sharedApplication].keyWindow];
        self.layer.frame = CGRectMake(translation.x + minX, translation.y + minY, width, height);
        [recognizer setTranslation:CGPointZero inView:self.superview];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (recognizer.view.center.x != self.superview.center.x || recognizer.view.center.y != self.superview.center.y) {
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.frame = CGRectMake(0, 0, width,height);
            } completion:^(BOOL finished) {
            }];
        }
    }
}

- (void)commitTranslation:(UIPanGestureRecognizer *)panGesture {/** 判断手势方向  */
    if (![panGesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        return;//类型安全
    }
    CGPoint translation = [panGesture translationInView:self];
    CGFloat absX = fabs(translation.x);
    CGFloat absY = fabs(translation.y);
    // 设置滑动有效距离
    if (MAX(absX, absY) < 1){
        return;
    }
    if (translation.x<0) {//向左滑动
        _moveDirection = MoveLeft;
    }
    if (translation.x>0) {//向右滑动
        _moveDirection = MoveRight;
    }
    if (translation.y>0) {//向下滑动
        _moveDirection = MoveBottom;
        if (translation.x>0) {
            _moveDirection =  MoveRightBottom;
        }
        if (translation.x<0) {
            _moveDirection =  MoveLeftBottom;
        }
    }
    if (translation.y<0) {//向上滑动
        _moveDirection = MoveTop;
        if (translation.x>0) {
            _moveDirection =  MoveRightTop;
        }
        if (translation.x<0) {
            _moveDirection =  MoveLeftTop;
        }
    }
}

-(BOOL)isMoveMapView{
    CGFloat offect = 5;
    //屏幕边缘的经纬度
    CLLocationDegrees leftLonBorder  = [self convertPoint:CGPointMake(-offect,0) toCoordinateFromView:self].longitude;
    CLLocationDegrees topLatBorder   = [self convertPoint:CGPointMake(0, -offect) toCoordinateFromView:self].latitude;
    
    CLLocationDegrees rightLonBorder = [self convertPoint:CGPointMake(CGRectGetWidth(self.frame)+ offect,  CGRectGetHeight(self.frame)) toCoordinateFromView:self].longitude;
    CLLocationDegrees botLatBorder = [self convertPoint:CGPointMake(CGRectGetWidth(self.frame),  CGRectGetHeight(self.frame) + offect) toCoordinateFromView:self].latitude;
    
    CLLocationDegrees lonLeft  = _groundOverlay.bounds.southWest.longitude;
    CLLocationDegrees lonRight = _groundOverlay.bounds.northEast.longitude;
    CLLocationDegrees latTop   = _groundOverlay.bounds.northEast.latitude;
    CLLocationDegrees latBot   = _groundOverlay.bounds.southWest.latitude;
    
    if (leftLonBorder <= lonLeft && _moveDirection == MoveRight) {//向右
        return YES;
    }
    if (topLatBorder >= latTop && _moveDirection == MoveBottom) {//向下
        return YES;
    }
    if (rightLonBorder >= lonRight && _moveDirection == MoveLeft) {//向左
        return YES;
    }
    if (botLatBorder <= latBot && _moveDirection == MoveTop) {//向上
        return YES;
    }
    
    if (leftLonBorder <= lonLeft && topLatBorder >= latTop && _moveDirection == MoveRightBottom) {//向右下
        return YES;
    }
    
    if (topLatBorder >= latTop && rightLonBorder >= lonRight && _moveDirection == MoveLeftBottom) {//向左下
        return YES;
    }
    
    if (leftLonBorder <= lonLeft && botLatBorder <= latBot && _moveDirection == MoveRightTop) {//向右上
        return YES;
    }
    
    if (rightLonBorder >= lonRight && botLatBorder <= latBot && _moveDirection == MoveLeftTop) {//左上
        return YES;
    }
    
    if (leftLonBorder <= lonLeft && topLatBorder >= latTop  && rightLonBorder >= lonRight  && botLatBorder  <= latBot) {
        return YES;
    }
    return NO;
}
@end
