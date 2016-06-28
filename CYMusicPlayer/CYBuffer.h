//
//  CYBuffer.h
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/21.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "CYParasedData.h"

@interface CYBuffer : NSObject
+ (instancetype) buffer;

- (void) enqueueData: (CYParasedData *) data;
- (void) enqueueFromDataArray: (NSArray *) dataArray;

- (BOOL) hasData;
- (UInt32) bufferedSize;

- (NSData *) dequeueDataWithSize: (UInt32) requiredSize packetCount: (UInt32 *) packetCount desciprtions: (AudioStreamPacketDescription **) descriptions;
- (void) clean;
@end
