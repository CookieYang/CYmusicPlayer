//
//  NSTimer+BlockSupport.h
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/9.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (BlockSupport)
+ (NSTimer*) CY_scheduledTimerWithTimeInterval:(NSTimeInterval)interval block:(void(^)())block repeats:(BOOL)repeats;
@end
