//
//  CYMusicPlayer.m
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/20.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "CYMusicPlayer.h"


@interface CYMusicPlayer ()
{
    @private
    NSThread *_thread;
    pthread_mutex_t _mutex;
    pthread_cond_t _cond;
    
    CYPlayerStatus _status;
    
    unsigned long long _fileSize;
    unsigned long long _offSet;
    NSFileHandle *_fileHandler;
    
    UInt32 _bufferSize;
//  文件和缓存块对象
    
    BOOL _started;
    BOOL _pauseRequired;
    BOOL _stopRequired;
    BOOL _pausedByInterrupt;
    BOOL _usingAudioFile;
    BOOL _seekRequired;
    
    NSTimeInterval _seekTime;
    NSTimeInterval _timingOffset;
}
@end

@implementation CYMusicPlayer
@dynamic status;
@synthesize failed = _failed;
@synthesize filePath = _filePath;
@synthesize fileType = _fileType;
@dynamic isPlayingOrWaiting;
@dynamic duration;
@dynamic progress;



@end
