//
//  CYbaseNavController.m
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/2.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "CYbaseNavController.h"

@implementation CYbaseNavController
+ (void)initialize {
    [UINavigationBar appearance].translucent = NO;
    [[UINavigationBar appearance] setBarTintColor: [UIColor colorWithPatternImage: [UIImage imageNamed: @"input_login_line"]]];
    [[UINavigationBar appearance] setTintColor: [UIColor whiteColor]];
}

@end
