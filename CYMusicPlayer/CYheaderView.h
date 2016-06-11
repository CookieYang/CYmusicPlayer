//
//  CYheaderView.h
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/2.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import <UIKit/UIKit.h>

// 按下按钮通知主页面翻页的协议
@protocol CYheaderViewDelegate <NSObject>
@optional
- (void) changePage: (NSInteger) selectedPageNum;
@end

@interface CYheaderView : UIView
@property (copy , nonatomic) NSArray<NSString*> *titles;
@property (assign , nonatomic) NSInteger selectedPage;
@property (weak, nonatomic) id<CYheaderViewDelegate> delegate;
- (instancetype) initWithFrame:(CGRect)frame andtitles:(NSArray *) titles;
@end
