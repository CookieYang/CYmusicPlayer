//
//  NSTimer+BlockSupport.m
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/9.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "NSTimer+BlockSupport.h"

@implementation NSTimer (BlockSupport)
+ (NSTimer *)CY_scheduledTimerWithTimeInterval:(NSTimeInterval)interval block:(void (^)())block repeats:(BOOL)repeats {
   return  [self scheduledTimerWithTimeInterval: interval target: self selector: @selector(CY_blockInvoke:) userInfo: block repeats: repeats];
}

+ (void) CY_blockInvoke:(NSTimer*)timer
{
    void (^block)() = timer.userInfo;
    if (block)
    {
        block();
    }
}
@end
