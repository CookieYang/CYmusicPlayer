//
//  CYfile.h
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/25.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioFile.h>
#import "CYParasedData.h"

@interface CYfile : NSObject
@property (copy , nonatomic, readonly) NSString *filePath;
@property (assign , nonatomic, readonly) AudioFileTypeID fileType;

@property (assign , nonatomic, readonly) BOOL available;
@property (assign , nonatomic, readonly) AudioStreamBasicDescription format;
@property (assign , nonatomic, readonly) unsigned long  long fileSize;
@property (assign , nonatomic, readonly) NSTimeInterval duration;
@property (assign , nonatomic, readonly) UInt32 bitRate;
@property (assign , nonatomic, readonly) UInt32 maxPacketSize;
@property (assign , nonatomic, readonly) UInt64 audioDataByteCount;

- (instancetype) initWithFilePath: (NSString *) filePath fileType: (AudioFileTypeID) fileType;
- (NSData *) fentchMagicCookie;
- (NSArray *) parseData: (BOOL *) isEof;
- (void) seekToTime: (NSTimeInterval) time;
- (void) close;
@end
