//
//  CYFileStream.h
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/22.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CYParasedData.h"

@class CYFileStream;
@protocol CYFileStreamDelegate <NSObject>
@required
- (void) fileStream: (CYFileStream *) fileStream DataParsed: (NSArray *) datas;
@optional
- (void) fileStreamReadyToProducePackets: (CYFileStream *) fileStream;
@end

@interface CYFileStream : NSObject
@property (assign , nonatomic, readonly) AudioFileTypeID fileType;
@property (assign , nonatomic, readonly) BOOL available;
@property (assign , nonatomic, readonly) BOOL readyToProducePackets;
@property (weak, nonatomic) id<CYFileStreamDelegate> delegate;

@property (assign , nonatomic, readonly) AudioStreamBasicDescription format;
@property (assign , nonatomic, readonly) unsigned long  long fileSize;
@property (assign , nonatomic, readonly) NSTimeInterval duration;
@property (assign , nonatomic, readonly) UInt32 bitRate;
@property (assign , nonatomic, readonly) UInt32 maxPacketSize;
@property (assign , nonatomic, readonly) UInt64 audioDataByteCount;

- (instancetype) initWithFileType: (AudioFileTypeID) fileType fileSize: (unsigned long long) fileSize error:(NSError **) error;
- (BOOL) parseData: (NSData *) data error: (NSError **) error;

- (SInt64) seekToTime: (NSTimeInterval *) time;

- (NSData *) fetchMagicCookie;
- (void) close;
@end
