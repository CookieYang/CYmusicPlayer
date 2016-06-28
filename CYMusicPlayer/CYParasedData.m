//
//  CYParasedData.m
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/21.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "CYParasedData.h"

@implementation CYParasedData
@synthesize data = _data;
@synthesize packetDesciption = _packetDesciption;

+ (instancetype) parasedAudioDataWithBytes:(const void *)bytes packetDesciption:(AudioStreamPacketDescription)packetDesciption {
    return [[self alloc] initWithBytes: bytes packetDesciption: packetDesciption];
}

- (instancetype) initWithBytes: (const void *)bytes packetDesciption: (AudioStreamPacketDescription) packetDesciption {
    if (bytes == NULL || packetDesciption.mDataByteSize == 0)
        return nil;
    
    if (self = [super init]) {
            _packetDesciption = packetDesciption;
            _data = [NSData dataWithBytes: bytes length: packetDesciption.mDataByteSize];
    }
           return self;
}
@end
