//
//  CYoutputQueue.h
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/28.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface CYoutputQueue : NSObject
@property (assign , nonatomic, readonly) BOOL available;
@property (assign , nonatomic, readonly) AudioStreamBasicDescription format;
@property (assign , nonatomic) float volume;
@property (assign , nonatomic) UInt32 bufferSize;
@property (assign , nonatomic, readonly) BOOL isRunning;

@property (assign , nonatomic, readonly) NSTimeInterval playedTime;

- (instancetype) initWithFormat: (AudioStreamBasicDescription) format bufferSize: (UInt32) bufferSize magicCookie: (NSData *) magicCookie;

- (BOOL) palyData: (NSData *) data packetCount: (UInt32) packetCount packetDescriptions: (AudioStreamPacketDescription *) packetDescriptions isEof: (BOOL) isEof;

- (BOOL) pause;
- (BOOL) resume;

- (BOOL) stop: (BOOL) immediately;

- (BOOL) reset;
- (BOOL) flush;

- (BOOL) setProperty:(AudioQueuePropertyID) propertyID dataSize: (UInt32) dataSize data: (const void *)data error: (NSError **)outError;
- (BOOL) getProperty:(AudioQueuePropertyID) propertyID dataSize: (UInt32 *) dataSize data: (void *) data error: (NSError **) outError;
- (BOOL) setParameter: (AudioQueueParameterID) parameterID value: (AudioQueueParameterValue) value error: (NSError **) outError;
- (BOOL) getParameter: (AudioQueueParameterID) parameterID value: (AudioQueueParameterValue *) value error: (NSError **) outError;
 @end
