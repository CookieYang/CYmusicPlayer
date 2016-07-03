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
@property (assign , nonatomic) UInt32 bufferedSize;
@end

@implementation CYBuffer

+ (instancetype) buffer {
    return [[self alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
       _bufferBlockArray = [NSMutableArray new];
    }
    return self;
}

- (BOOL)hasData {
    return _bufferBlockArray.count > 0;
}

- (UInt32)bufferedSize {
    return _bufferedSize;
}

- (void) enqueueFromDataArray:(NSArray *) dataArray {
    for (CYParasedData *data in dataArray) {
        [self enqueueData: data];
    }
}

- (void)enqueueData:(CYParasedData *)data {
    if ([data isKindOfClass: [CYParasedData class]]) {
        
        [_bufferBlockArray addObject: data];
        _bufferedSize += data.data.length;
    }
}

- (NSData *)dequeueDataWithSize:(UInt32)requiredSize packetCount:(UInt32 *)packetCount desciprtions:(AudioStreamPacketDescription **)descriptions {
    if (requiredSize == 0 && _bufferBlockArray.count == 0) {
        return nil;
    }
    
    SInt64 size = requiredSize;
    int i = 0;
    for (i = 0; i < _bufferBlockArray.count; i++) {
        CYParasedData *block = _bufferBlockArray[i];
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
    
    UInt32 count = (i >= _bufferBlockArray.count) ? (UInt32)_bufferBlockArray.count : (i + 1);
    *packetCount = count;
    if (count == 0) {
        return nil;
    }
    
    if (descriptions != NULL) {
        *descriptions = (AudioStreamPacketDescription *)malloc(sizeof(AudioStreamPacketDescription) * count);
    }
    
    NSMutableData *retData = [NSMutableData new];
    for (int j = 0; j < count; ++j) {
        CYParasedData *block = _bufferBlockArray[j];
        if (descriptions != NULL) {
            AudioStreamPacketDescription desc = block.packetDesciption;
            desc.mStartOffset = [retData length];
            (*descriptions)[j] = desc;
        }
        [retData appendData: block.data];
    }
    NSRange removeRange = NSMakeRange(0, count);
    [_bufferBlockArray removeObjectsInRange: removeRange];
    
    _bufferedSize -= retData.length;
    return retData;
}

- (void)clean {
    _bufferedSize = 0;
    [_bufferBlockArray removeAllObjects];
}

-(void)dealloc {
    [_bufferBlockArray removeAllObjects];
}
@end
