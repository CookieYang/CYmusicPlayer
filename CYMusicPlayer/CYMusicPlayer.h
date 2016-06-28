//
//  CYMusicPlayer.h
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/20.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef NS_ENUM(NSUInteger, CYPlayerStatus) {
    CYMusicPlayerStopped = 0,
    CYMusicPlayerPlaying = 1,
    CYMusicPlayerWaiting = 2,
    CYMusicPlayerPaused = 3,
    CYMusicPlayerFlushing = 4,
};

@interface CYMusicPlayer : NSObject
@property (copy , nonatomic, readonly) NSString *filePath;
@property (assign , nonatomic, readonly) AudioFileTypeID fileType;

@property (assign , nonatomic, readonly) CYPlayerStatus status;
@property (assign , nonatomic, readonly) BOOL isPlayingOrWaiting;
@property (assign , nonatomic, readonly) BOOL failed;

// 进度需要可以修改
@property (assign , nonatomic) NSTimeInterval progress;
@property (assign , nonatomic, readonly) NSTimeInterval duration;

- (instancetype) initWithFilePath: (NSString *) filePath fileType: (AudioFileTypeID) fileType;
- (void) play;
- (void) stop;
- (void) pause;
@end
