//
//  CYPlayButton.m
//  test
//
//  Created by 杨涛 on 16/6/6.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "CYPlayButton.h"

@implementation CYPlayButton
- (instancetype)initWithFrame:(CGRect)frame {
    if (self= [super initWithFrame: frame]) {
        self.enabled = NO;
        self.adjustsImageWhenHighlighted = NO;
        // 失效状态
        [self setBackgroundImage: [UIImage imageNamed: @"miniplayer_btn_play_disable"] forState: UIControlStateDisabled];
}
    return self;
}

- (void)setIsPause:(BOOL)isPause{
    self.enabled = YES;
    [self setBackgroundImage: [UIImage imageNamed: @"button_back_bg"] forState: UIControlStateNormal];
    
    //播放状态
    if (!isPause) {
        [self setImage: [UIImage imageNamed: @"miniplayer_btn_pause_normal"] forState: UIControlStateNormal];
        [self setImage: [UIImage imageNamed: @"miniplayer_btn_pause_highlight"] forState: UIControlStateHighlighted];
    } else {
        [self setImage: [UIImage imageNamed: @"miniplayer_btn_play_normal"] forState: UIControlStateNormal];
        [self setImage: [UIImage imageNamed: @"miniplayer_btn_play_highlight"] forState: UIControlStateHighlighted];
    }
}

- (void)drawRect: (CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
    
    CGContextSetLineWidth(context, 3.0);//线的宽度
    
    CGContextAddArc(context, self.bounds.size.width / 2, self.bounds.size.height / 2, rect.size.width / 2 - 2, - M_PI / 2, - M_PI / 2 + 2 * M_PI * self.progress, 0);//添加一个圆，x,y为圆点坐标，radius半径，startAngle为开始的弧度，endAngle为 结束的弧度，clockwise 0为顺时针，1为逆时针。
    
    CGContextDrawPath(context, kCGPathStroke);//绘制路径
}
@end
