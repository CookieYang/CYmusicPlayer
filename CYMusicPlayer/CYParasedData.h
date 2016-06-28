//
//  CYParasedData.h
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/21.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface CYParasedData : NSObject
@property (strong , nonatomic, readonly) NSData *data;
@property (assign , nonatomic, readonly) AudioStreamPacketDescription packetDesciption;

+ (instancetype) parasedAudioDataWithBytes: (const void *) bytes packetDesciption: (AudioStreamPacketDescription) packetDesciption;
@end
