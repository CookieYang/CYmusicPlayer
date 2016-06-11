//
//  UIView+ViewAnimation.m
//  test
//
//  Created by 杨涛 on 16/6/7.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "UIView+ViewAnimation.h"

@implementation UIView (ViewAnimation)

- (void) addFlashAnimationToLabel: (UILabel *) label {
    
    self.frame = label.frame;
    self.backgroundColor = [UIColor clearColor];
    
    CAGradientLayer *layer = [CAGradientLayer new];
    
    layer.bounds =  self.bounds;
    layer.position = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    
    layer.contentsScale = [UIScreen mainScreen].scale;
    
    layer.startPoint = CGPointMake(0, 0.5);
    layer.endPoint = CGPointMake(1, 0.5);
    
    UIColor *textColor = label.textColor;
    
    layer.colors = @[(id)[textColor CGColor],
                    (id)[[UIColor whiteColor] CGColor],
                    (id)[textColor CGColor]];
    
    layer.locations = @[@0.2, @0.5, @0.8];

    [self.layer addSublayer: layer];
    [self startAnimation: layer];
    
    label.frame = self.bounds;
    [self addSubview: label];
    
    layer.mask =label.layer;
}

- (void) startAnimation: (CAGradientLayer *) layer {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath: @"locations"];
    animation.fromValue = @[@0, @0, @0.25];
    animation.toValue = @[@0.75, @1, @1];
    animation.duration = 2;
    animation.repeatCount = HUGE_VALF;
    [layer addAnimation: animation forKey: nil];
}
@end
