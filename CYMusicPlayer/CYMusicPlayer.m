//
//  CYMusicPlayer.m
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/20.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "CYMusicPlayer.h"
#import "CYfile.h"
#import "CYFileStream.h"
#import "CYoutputQueue.h"
#import "CYBuffer.h"
#import <pthread.h>
#import "CYVminiPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface CYMusicPlayer () <CYFileStreamDelegate>
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
    CYBuffer *_buffer;
    
    CYfile *_audioFile;
    CYFileStream *_audioFileStream;
    CYoutputQueue *_audioQueue;
    
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

#pragma mark - 初始化和销毁方法
- (instancetype)initWithFilePath:(NSString *)filePath fileType:(AudioFileTypeID)fileType {
    if (self = [super init]) {
        _status = CYMusicPlayerStopped;
        _filePath = filePath;
        _fileType = fileType;
        
        _fileHandler = [NSFileHandle fileHandleForReadingAtPath: _filePath];
        _fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath: _filePath error: nil] fileSize];
        if (_fileHandler && _fileSize > 0) {
            _buffer = [CYBuffer buffer];
        } else {
            [_fileHandler closeFile];
            _failed = YES;
        }
    }
    return self;
}

- (void) dealloc {
    [self removeObserver: [CYVminiPlayer sharedSingledefaultPlayer] forKeyPath: @"status"];
    [self cleanUp];
    [_fileHandler closeFile];
}

#pragma mark - status
- (BOOL) isPlayingOrWaiting {
    return self.status == CYMusicPlayerWaiting || self.status == CYMusicPlayerPlaying || self.status == CYMusicPlayerFlushing;
}

- (CYPlayerStatus)status {
    return _status;
}

- (void) setStatusInternal: (CYPlayerStatus) status {
    if (_status == status) {
        return;
    }
    [self willChangeValueForKey: @"status"];
    _status = status;
    [self didChangeValueForKey: @"status"];
}

- (void) cleanUp {
    _offSet = 0;
    [_fileHandler seekToFileOffset: 0];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [_buffer clean];
    
    _usingAudioFile = NO;
    [_audioFileStream close];
    _audioFileStream = nil;
    
    [_audioFile close];
    _audioFile = nil;
    
    [_audioQueue stop: YES];
    _audioQueue = nil;
    
    [self mutexDestory];
    
    _started = NO;
    _timingOffset = 0;
    _seekTime = 0;
    _seekRequired = NO;
    _pauseRequired = NO;
    _stopRequired = NO;
    
    [self setStatusInternal: CYMusicPlayerStopped];
}
#pragma  mark - 同步线程
- (void) mutexInit {
    pthread_mutex_init(&_mutex, NULL);
    pthread_cond_init(&_cond, NULL);
}

- (void) mutexDestory {
    pthread_mutex_destroy(&_mutex);
    pthread_cond_destroy(&_cond);
}

- (void) mutexWait {
    pthread_mutex_lock(&_mutex);
    pthread_cond_wait(&_cond, &_mutex);
    pthread_mutex_unlock(&_mutex);
}

- (void) mutexSingal {
    pthread_mutex_lock(&_mutex);
    pthread_cond_signal(&_cond);    
    pthread_mutex_unlock(&_mutex);
}

#pragma mark - thread
- (BOOL) createAudioQueue {
    if (_audioQueue) {
        return YES;
    }
    
    NSTimeInterval duration = self.duration;
    UInt64 audioDataByteCount = _usingAudioFile ? _audioFile.audioDataByteCount : _audioFileStream.audioDataByteCount;
    _bufferSize = 0;
    if (duration != 0) {
        _bufferSize = (0.2 / duration) * audioDataByteCount;
    }
    
    if (_bufferSize > 0) {
        AudioStreamBasicDescription format = _usingAudioFile ? _audioFile.format : _audioFileStream.format;
        NSData *magicCookie = _usingAudioFile ? [_audioFile fentchMagicCookie] : [_audioFileStream fetchMagicCookie];
        _audioQueue = [[CYoutputQueue alloc] initWithFormat: format bufferSize: _bufferSize magicCookie: magicCookie];
        if (!_audioQueue.available) {
            _audioQueue = nil;
            return NO;
        }
    }
    return YES;
}

- (void) threadMain {
    _failed = YES;
    NSError *error = nil;
    
    if ([[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: NULL]) {
        
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(interruptHandler:) name:AVAudioSessionInterruptionNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(routeChangeHandler:) name:AVAudioSessionRouteChangeNotification object: nil];
        
        if ([[AVAudioSession sharedInstance] setActive: YES error: NULL]) {
            _audioFileStream = [[CYFileStream alloc] initWithFileType: _fileType fileSize: _fileSize error: &error];
            if (!error) {
                _failed = NO;
                _audioFileStream.delegate = self;
            }
        }
    }
    
    if (_failed) {
        [self cleanUp];
        return;
    }
    
    [self setStatusInternal: CYMusicPlayerWaiting];
    BOOL isEof = NO;
    
    // 进入播放循环
    while (self.status != CYMusicPlayerStopped && !_failed && _started) {
        @autoreleasepool {
            if (_usingAudioFile) {
                if (!_audioFile) {
                    _audioFile = [[CYfile alloc] initWithFilePath: _filePath fileType: _fileType];
                }
                [_audioFile seekToTime: _seekTime];
                if ([_buffer bufferedSize] < _bufferSize || !_audioQueue) {
                    NSArray *parsedData = [_audioFile parseData: &isEof];
                    if (parsedData) {
                        [_buffer enqueueFromDataArray: parsedData];
                    } else {
                        _failed = YES;
                        break;
                    }
                }
            } else {
                if (_offSet < _fileSize && (!_audioFileStream.readyToProducePackets || [_buffer bufferedSize] < _bufferSize || !_audioQueue)) {
                    NSData *data = [_fileHandler readDataOfLength: 1000];
                    _offSet += [data length];
                    if (_offSet >= _fileSize) {
                        isEof = YES;
                    }
                    [_audioFileStream parseData: data error: &error];
                    if (error) {
                        _usingAudioFile = YES;
                        continue;
                    }
                }
            }
            
            if (_audioFileStream.readyToProducePackets || _usingAudioFile) {
                if (![self createAudioQueue]) {
                    _failed = YES;
                    break;
                }
                
                if (!_audioQueue) {
                    continue;
                }
                
                if (self.status == CYMusicPlayerFlushing && !_audioQueue.isRunning) {
                    break;
                }
                
                if (_stopRequired) {
                    _stopRequired = NO;
                    _started = NO;
                    [_audioQueue stop: YES];
                    break;
                }
                
                if (_pauseRequired) {
                    [self setStatusInternal: CYMusicPlayerPaused];
                    [_audioQueue pause];
                    [self mutexWait];
                    _pauseRequired = NO;
                }
                
                
                if ([_buffer bufferedSize] >= _bufferSize || isEof) {
                    UInt32 packetCount;
                    AudioStreamPacketDescription *deces = NULL;
                    NSData *data = [_buffer dequeueDataWithSize: _bufferSize packetCount: &packetCount desciprtions: &deces];
                  
                    if (packetCount != 0) {
                        [self setStatusInternal: CYMusicPlayerPlaying];
                        _failed = ![_audioQueue palyData: data packetCount: packetCount packetDescriptions: deces isEof: isEof];
                        free(deces);
                        if (_failed) {
                            break;
                        }
                        if (![_buffer hasData] && isEof && _audioQueue.isRunning) {
                            [_audioQueue stop: NO];
                            [self setStatusInternal: CYMusicPlayerFlushing];
                        }
                    } else if (isEof) {
                        // wait for end
                        if (![_buffer hasData] && _audioQueue.isRunning) {
                            [_audioQueue stop: NO];
                            [self setStatusInternal: CYMusicPlayerFlushing];
                        }
                    } else {
                        _failed = YES;
                        break;
                    }
                }
                
                if (_seekRequired && self.duration != 0) {
                    [self setStatusInternal: CYMusicPlayerWaiting];
                    _timingOffset = _seekTime - _audioQueue.playedTime;
                    [_buffer clean];
                    if (_usingAudioFile) {
                        [_audioFile seekToTime: _seekTime];
                    } else {
                        _offSet = [_audioFileStream seekToTime: &_seekTime];
                        [_fileHandler seekToFileOffset: _offSet];
                    }
                    _seekRequired = NO;
                    [_audioQueue reset];
                }
            }
        }
    }
    [self cleanUp];
}

#pragma mark - 通知方法
- (void) interruptHandler: (NSNotification *) notification {
    UInt32 interruptState = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntValue];
    
    if (interruptState == AVAudioSessionInterruptionTypeBegan) {
        _pausedByInterrupt = YES;
        [_audioQueue pause];
        [self setStatusInternal: CYMusicPlayerPaused];
    } else if (interruptState == AVAudioSessionInterruptionTypeEnded) {
        AVAudioSessionInterruptionOptions interruptionType = [notification.userInfo[AVAudioSessionInterruptionOptionKey] unsignedIntValue];
        if (interruptionType == AVAudioSessionInterruptionOptionShouldResume) {
            if (self.status == CYMusicPlayerPaused && _pausedByInterrupt) {
                if ([[AVAudioSession sharedInstance] setActive: YES error: NULL]) {
                    [self play];
                }
            }
        }
   }
}

- (void) routeChangeHandler: (NSNotification *) notification {
    
}

#pragma mark - parser 
- (void) fileStream: (CYFileStream *) fileStream DataParsed: (NSArray *) datas {
    
    [_buffer enqueueFromDataArray: datas];
}

#pragma mark - progress
- (NSTimeInterval) progress {
    if (_seekRequired) {
        return _seekTime;
    }
    return _timingOffset + _audioQueue.playedTime;
}

- (void) setProgress:(NSTimeInterval)progress {
    _seekRequired = YES;
    _seekTime = progress;
}

- (NSTimeInterval) duration {
    return _usingAudioFile ? _audioFile.duration : _audioFileStream.duration;
}

#pragma mark - 播放控制
- (void) play {
    if (!_started) {
        _started = YES;
        [self mutexInit];
        _thread = [[NSThread alloc] initWithTarget: self selector: @selector(threadMain) object: nil];
        [_thread start];
    } else {
        if (_status == CYMusicPlayerPaused || _pauseRequired) {
            _pausedByInterrupt = NO;
            _pauseRequired = NO;
            if ([[AVAudioSession sharedInstance] setActive: YES error: NULL]) {
                [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: NULL];
                [self resume];
            }
        }
    }
}

- (void) resume {
    [_audioQueue resume];
    [self mutexSingal];
}

- (void) pause {
    if (self.isPlayingOrWaiting && self.status != CYMusicPlayerFlushing) {
        _pauseRequired = YES;
    }
}

- (void) stop {
    _stopRequired = YES;
    [self mutexSingal];
}
@end
