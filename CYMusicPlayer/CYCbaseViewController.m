//
//  CYCbaseViewController.m
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/9.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "CYCbaseViewController.h"
#import "CYVminiPlayer.h"
#import "Masonry.h"

@interface CYCbaseViewController ()
@end

@implementation CYCbaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // 添加miniPlayer
    CYVminiPlayer *miniPlayer = [[CYVminiPlayer alloc] initWithFrame: CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    [self.view addSubview: miniPlayer];
    [miniPlayer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(@50);
    }];
}

@end
