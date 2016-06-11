//
//  CYPlayButton.h
//  test
//
//  Created by 杨涛 on 16/6/6.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CYPlayButton : UIButton
@property (assign , nonatomic) CGFloat progress;
@property (assign , nonatomic) BOOL isPause;
- (void) setProgress:(CGFloat) progress;
- (void)setIsPause:(BOOL)isPause;
@end
