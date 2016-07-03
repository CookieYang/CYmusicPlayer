//
//  CYoutputQueue.m
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/28.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "CYoutputQueue.h"
#import <pthread.h>

const int CYQueueBufferCount= 2;

@interface CYQueueBuffer: NSObject
@property (assign , nonatomic) AudioQueueBufferRef buffer;
@end
@implementation CYQueueBuffer
@end

@interface CYoutputQueue ()
@property (assign , nonatomic) AudioQueueRef audioQueue;
@property (copy , nonatomic) NSMutableArray *buffers;
@property (copy , nonatomic) NSMutableArray *reusableBuffers;

@property (assign , nonatomic) BOOL isRunning;
@property (assign , nonatomic) BOOL started;
@property (assign , nonatomic) NSTimeInterval playedTime;

@property (assign , nonatomic) pthread_mutex_t mutex;
@property (assign , nonatomic) pthread_cond_t cond;
@end

@implementation CYoutputQueue
@synthesize format = _format;
@dynamic available;
@synthesize volume = _volume;
@synthesize bufferSize = _bufferSize;
@synthesize isRunning = _isRunning;

#pragma mark - 初始化和销毁
- (instancetype)initWithFormat:(AudioStreamBasicDescription)format bufferSize:(UInt32)bufferSize magicCookie:(NSData *)magicCookie {
    if (self = [super init]) {
        _format = format;
        _volume = 1.0f;
        _bufferSize = bufferSize;
        _buffers = [NSMutableArray new];
        _reusableBuffers = [NSMutableArray new];
        [self createAudioOutputQueue: magicCookie];
        [self mutexinit];
    }
    return self;
}

- (void)dealloc {
    [self disposeAudioOutputQueue];
    [self mutexDestory];
}
#pragma mark - error
- (void) errorForOSStatus: (OSStatus) status error: (NSError * __autoreleasing*) outError {
    if (status != noErr && outError != NULL) {
        *outError = [NSError errorWithDomain: NSOSStatusErrorDomain code: status userInfo: nil];
    }
}

#pragma mark - 创建销毁queue
- (void) createAudioOutputQueue: (NSData *) magicCookie {
    OSStatus status = AudioQueueNewOutput(&_format, CYaudioQueueOutputCallback, (__bridge void *)(self), NULL, NULL, 0, &_audioQueue);
    if (status != noErr) {
        _audioQueue = NULL;
        return;
    }
    
    status = AudioQueueAddPropertyListener(_audioQueue, kAudioQueueProperty_IsRunning, CYaudioQueuePropertyCallback, (__bridge void *)(self));
    if (status != noErr) {
        AudioQueueDispose(_audioQueue, YES);
        _audioQueue = NULL;
        return;
    }
    
    if (_buffers.count == 0) {
        for (int i = 0; i < CYQueueBufferCount; i++) {
            AudioQueueBufferRef buffer;
            status = AudioQueueAllocateBuffer(_audioQueue, _bufferSize, &buffer);
            if (status != noErr) {
                AudioQueueDispose(_audioQueue, YES);
                _audioQueue = NULL;
                break;
            }
            CYQueueBuffer *bufferObj = [CYQueueBuffer new];
            bufferObj.buffer = buffer;
            [_buffers addObject: bufferObj];
            [_reusableBuffers addObject: bufferObj];
        }
    }
    
#if TARGET_OS_IPHONE
    UInt32 property = kAudioQueueHardwareCodecPolicy_PreferSoftware;
    [self setProperty: kAudioQueueProperty_HardwareCodecPolicy dataSize: sizeof(property) data: &property error:NULL];
#endif
    
    if (magicCookie) {
        AudioQueueSetProperty(_audioQueue, kAudioQueueProperty_MagicCookie, [magicCookie bytes], (UInt32)[magicCookie length]);
    }
    [self setVolumeParameter];
}

- (void) disposeAudioOutputQueue {
    if (_audioQueue != NULL) {
        AudioQueueDispose(_audioQueue, true);
        _audioQueue = NULL;
    }
}

- (BOOL) start {
    OSStatus status = AudioQueueStart(_audioQueue, NULL);
    _started = status == noErr;
    return _started;
}

- (BOOL) resume {
    return [self start];
}

- (BOOL)pause {
    OSStatus status = AudioQueuePause(_audioQueue);
    _started = NO;
    return status == noErr;
}

- (BOOL)reset {
    OSStatus status = AudioQueueReset(_audioQueue);
    return status == noErr;
}

- (BOOL)flush {
    OSStatus status = AudioQueueFlush(_audioQueue);
    return status == noErr;
}

- (BOOL)stop:(BOOL)immediately {
    OSStatus status = noErr;
    if (immediately) {
        status = AudioQueueStop(_audioQueue, true);
    } else {
        status = AudioQueueStop(_audioQueue, false);
    }
    _started = NO;
    _playedTime = 0;
    return  status == noErr;
}

- (BOOL) palyData: (NSData *) data packetCount: (UInt32) packetCount packetDescriptions: (AudioStreamPacketDescription *) packetDescriptions isEof: (BOOL) isEof{
    if ([data length] > _bufferSize) {
        return NO;
    }
 
    if (_reusableBuffers.count == 0) {
        if (!_started && ![self start]) {
            return NO;
        }
        
        [self mutexWait];
    }
    
    CYQueueBuffer *bufferObj = [_reusableBuffers firstObject];
    [_reusableBuffers removeObject:  bufferObj];
    if (!bufferObj) {
        AudioQueueBufferRef buffer;
        OSStatus status = AudioQueueAllocateBuffer(_audioQueue, _bufferSize, &buffer);
        if (status == noErr) {
            bufferObj = [CYQueueBuffer new];
            bufferObj.buffer = buffer;
        } else {
            return NO;
        }
    }
    
    memcpy(bufferObj.buffer -> mAudioData, [data bytes], [data length]);
    bufferObj.buffer -> mAudioDataByteSize = (UInt32)[data length];
    
    OSStatus status = AudioQueueEnqueueBuffer(_audioQueue, bufferObj.buffer, packetCount, packetDescriptions);
    if (status == noErr) {
        if (_reusableBuffers.count == 0 || isEof) {
            if (!_started && ![self start]) {
                return NO;
            }
        }
    }
    return status == noErr;
}

- (BOOL)setProperty:(AudioQueuePropertyID)propertyID dataSize:(UInt32)dataSize data:(const void *)data error:(NSError *__autoreleasing *)outError {
    OSStatus status = AudioQueueSetProperty(_audioQueue, propertyID, data, dataSize);
    [self errorForOSStatus: status error: outError];
    return status == noErr;
}

- (BOOL)getProperty:(AudioQueuePropertyID)propertyID dataSize:(UInt32 *)dataSize data:(void *)data error:(NSError *__autoreleasing *)outError {
    OSStatus status = AudioQueueGetProperty(_audioQueue, propertyID, data, dataSize);
    [self errorForOSStatus: status error: outError];
    return status == noErr;
}

- (BOOL)setParameter:(AudioQueueParameterID)parameterID value:(AudioQueueParameterValue)value error:(NSError *__autoreleasing *)outError {
    OSStatus status = AudioQueueSetParameter(_audioQueue, parameterID, value);
    [self errorForOSStatus: status error: outError];
    return status == noErr;
}

- (BOOL)getParameter:(AudioQueueParameterID)parameterID value:(AudioQueueParameterValue *)value error:(NSError *__autoreleasing *)outError {
    OSStatus status = AudioQueueGetParameter(_audioQueue, parameterID, value);
    [self errorForOSStatus: status error: outError];
    return  status == noErr;
}

#pragma mark - mutex
- (void) mutexinit {
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

- (void) mutexSignal {
    pthread_mutex_lock(&_mutex);
    pthread_cond_signal(&_cond);
    pthread_mutex_unlock(&_mutex);
}

#pragma mark - 属性
- (NSTimeInterval)playedTime {
    if (_format.mSampleRate == 0) {
        return 0;
    }
    AudioTimeStamp time;
    OSStatus status = AudioQueueGetCurrentTime(_audioQueue, NULL, &time, NULL);
    if (status == noErr) {
        _playedTime = time.mSampleTime / _format.mSampleRate;
    }
    return _playedTime;
}

- (BOOL)available {
    return _audioQueue != NULL;
}

- (void)setVolume:(float)volume {
    _volume = volume;
    [self setVolumeParameter];
}

- (void) setVolumeParameter {
    [self setParameter: kAudioQueueParam_Volume value: _volume error: NULL];
}

#pragma  mark - callBack
static void CYaudioQueuePropertyCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID) {
    CYoutputQueue *audioQueue = (__bridge CYoutputQueue *)(inUserData);
    [audioQueue handleAudioQueuePropertyCallBack: inAQ property:inID];
}

static void CYaudioQueueOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
       CYoutputQueue *audioQueue = (__bridge CYoutputQueue *)(inUserData);
       [audioQueue handleAudioQueueOutputCallBack: inAQ buffer: inBuffer];
}

- (void) handleAudioQueuePropertyCallBack: (AudioQueueRef) audioQueue property: (AudioQueuePropertyID) property {
    if (property == kAudioQueueProperty_IsRunning) {
        UInt32 isRunning = 0;
        UInt32 size = sizeof(isRunning);
        AudioQueueGetProperty(audioQueue, property, &isRunning, &size);
        _isRunning = isRunning;
    }
}

- (void) handleAudioQueueOutputCallBack: (AudioQueueRef) audioQueue buffer: (AudioQueueBufferRef) buffer {
    for (int i = 0; i < _buffers.count; i++) {
        if (buffer == [_buffers[i] buffer]) {
            [_reusableBuffers addObject: _buffers[i]];
            break;
        }
    }
    [self mutexSignal];
}

@end
