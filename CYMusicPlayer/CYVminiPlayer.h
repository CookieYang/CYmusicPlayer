//
//  CYVminiPlayer.h
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/9.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYPlayButton.h"
#import "CYSingleBase.h"

@interface CYVminiPlayer : UIView
CYSingle_h(defaultPlayer)
@property (strong , nonatomic) UILabel *authName;
@property (strong , nonatomic) UILabel *musicName;
@property (strong , nonatomic) UILabel *animationLabel;
@property (strong , nonatomic) UIButton *iconButton;
@property (strong , nonatomic) CYPlayButton *playButton;
@property (strong , nonatomic) UIButton *listButton;
@property (assign , nonatomic) BOOL isInitial;
@end
