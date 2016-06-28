//
//  CYBuffer.m
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/21.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "CYBuffer.h"

@interface CYBuffer ()
@property (copy , nonatomic) NSMutableArray *bufferBlockArray;
@property (assign , nonatomic) UInt32 bufferSize;
@end

@implementation CYBuffer

+ (instancetype) buffer {
    return [self new];
}

- (instancetype)init {
    if (self = [super init]) {
        self.bufferBlockArray = [NSMutableArray new];
    }
    return self;
}

- (BOOL)hasData {
    return self.bufferBlockArray.count > 0;
}

- (UInt32)bufferedSize {
    return self.bufferedSize;
}

- (void) enqueueFromDataArray:(NSArray *) dataArray {
    for (CYParasedData *data in dataArray) {
        [self enqueueData: data];
    }
}

- (void)enqueueData:(CYParasedData *)data {
    if ([data isKindOfClass: [CYParasedData class]]) {
        [self.bufferBlockArray addObject: data];
        _bufferSize += data.data.length;
    }
}

- (NSData *)dequeueDataWithSize:(UInt32)requiredSize packetCount:(UInt32 *)packetCount desciprtions:(AudioStreamPacketDescription **)descriptions {
    if (requiredSize == 0 && self.bufferBlockArray.count == 0) {
        return nil;
    }
    
    SInt64 size = requiredSize;
    int i = 0;
    for (; i < self.bufferBlockArray.count; i++) {
        CYParasedData *block = self.bufferBlockArray[i];
        SInt64 length = block.data.length;
        if (size > length) {
            size -= length;
        } else {
            if (size < length) {
                i--;
            }
            break;
        }
    }
    if (i < 0) {
        return nil;
    }
    
    UInt32 count = (i >= self.bufferBlockArray.count) ? (UInt32)self.bufferBlockArray.count : (i + 1);
    *packetCount = count;
    if (count == 0) {
        return nil;
    }
    
    if (descriptions != NULL) {
        *descriptions = (AudioStreamPacketDescription *)malloc(sizeof(AudioStreamPacketDescription) * count);
    }
    
    NSMutableData *retData = [NSMutableData new];
    for (int j = 0; j < count; ++j) {
        CYParasedData *block = self.bufferBlockArray[j];
        if (descriptions != NULL) {
            AudioStreamPacketDescription desc = block.packetDesciption;
            desc.mStartOffset = [retData length];
            (*descriptions)[j] = desc;
        }
        [retData appendData: block.data];
    }
    NSRange removeRange = NSMakeRange(0, count);
    [self.bufferBlockArray removeObjectsInRange: removeRange];
    
    _bufferSize -= retData.length;
    
    return retData;
}

- (void)clean {
    _bufferSize = 0;
    [self.bufferBlockArray removeAllObjects];
}

-(void)dealloc {
    [self.bufferBlockArray removeAllObjects];
}
@end
