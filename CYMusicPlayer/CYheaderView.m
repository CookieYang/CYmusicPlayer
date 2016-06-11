//
//  CYheaderView.m
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/2.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "CYheaderView.h"

@implementation CYheaderView 

- (instancetype) initWithFrame:(CGRect)frame andtitles:(NSArray *) titles {
    self.titles = titles;
    // 初始化控件
    if (self = [super initWithFrame: frame]) {
        for (NSInteger i = 0; i < self.titles.count; i++) {
            CGFloat buttonW = frame.size.width / self.titles.count;
            CGFloat buttonH = frame.size.height;
            CGFloat buttonX = i * buttonW;
            CGFloat buttonY = 0;
            UIButton *button = [[UIButton alloc] initWithFrame: CGRectMake(buttonX, buttonY, buttonW, buttonH)];
            [button setTitle: self.titles[i] forState: UIControlStateNormal];
            button.tag = i + 1;
            [button addTarget: self action: @selector(buttonSelected:) forControlEvents: UIControlEventTouchUpInside];
            [self addSubview: button];
        }
    }
    
    //手动来一次
    self.selectedPage = 1;
    return self;
}

- (void) setSelectedPage: (NSInteger)selectedPage {
    _selectedPage = selectedPage;
    UIButton *button = [self viewWithTag: _selectedPage];
    [self buttonSelected: button];
}

// 按钮功能
- (void) buttonSelected: (UIButton *) sender {
    _selectedPage = sender.tag;
    [sender.titleLabel setFont: [UIFont boldSystemFontOfSize: 20]];
    
    // 取消其他按钮的状态
    for (UIButton *btn in self.subviews) {
        if (btn.tag != self.selectedPage) {
            [btn.titleLabel setFont: [UIFont systemFontOfSize: 18]];
        }
    }
    if ([self.delegate respondsToSelector: @selector(changePage:)]) {
        [self.delegate changePage: sender.tag];
    }
}
@end
