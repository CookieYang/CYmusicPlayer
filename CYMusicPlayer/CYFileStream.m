//
//  CYFileStream.m
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/22.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "CYFileStream.h"

#define BitRateEstimationMaxPackets 5000
#define BitRateEstimationMinPackets 10

@interface CYFileStream ()
@property (assign , nonatomic) BOOL discontinuous;
@property (assign , nonatomic) AudioFileStreamID FileStreamID;

@property (assign , nonatomic) SInt64 dataOffset;
@property (assign , nonatomic) NSTimeInterval packetDuration;

@property (assign , nonatomic) UInt64 ProcessedPacketCount;
@property (assign , nonatomic) UInt64 ProcessedPacketSizeTotal;

- (void) handleAudioFileStreamProperty: (AudioFileStreamPropertyID) propertyID;
- (void) handleAudioFIleStreamPackets: (const void *) packets
                        numberOfBytes: (UInt32) numberOfBytes
                        numberOfPackets: (UInt32) numberOfPackets
                   packetDescriptions: (AudioStreamPacketDescription *) packetDescriptions;
@end

static void CYFileStreamPropertyListener(void *inClientData,
                                         AudioFileStreamID inAudioFileStream,
                                         AudioFileStreamPropertyID inPropertyID,
                                         UInt32 *ioFlags) {
    CYFileStream *fileStream = (__bridge CYFileStream *) inClientData;
    [fileStream handleAudioFileStreamProperty: inPropertyID];
}

static void CYFileStreamPacketsCallBack(void *inClientData,
                                        UInt32 inNumberBytes,
                                        UInt32 inNumberPackets,
                                        const void *inInputData,
                                        AudioStreamPacketDescription *inPacketDescriptions) {
    CYFileStream *fileStream = (__bridge CYFileStream *) inClientData;
    [fileStream handleAudioFIleStreamPackets: inInputData numberOfBytes: inNumberBytes numberOfPackets: inNumberPackets packetDescriptions: inPacketDescriptions];
}

@implementation CYFileStream
@synthesize fileType = _fileType;
@synthesize readyToProducePackets = _readyToProducePackets;
@dynamic available;
@synthesize delegate = _delegate;
@synthesize duration = _duration;
@synthesize bitRate = _bitRate;
@synthesize format = _format;
@synthesize maxPacketSize = _maxPacketSize;
@synthesize audioDataByteCount = _audioDataByteCount;

#pragma mark - 初始化和销毁方法

- (instancetype)initWithFileType:(AudioFileTypeID)fileType fileSize:(unsigned long long)fileSize error:(NSError *__autoreleasing *)error {
    if (self = [super init]) {
        self.discontinuous = NO;
        _fileType = fileType;
        fileSize = fileSize;
        [self openFileStreamWithFileTypeHint: _fileType error: error];
    }
    return  self;
}

- (void)dealloc {
    [self closeFileStream];
}

- (void) closeFileStream {
    if (self.available) {
        AudioFileStreamClose(_FileStreamID);
        _FileStreamID = NULL;
    }
}

- (void)close {
    [self closeFileStream];
}

- (BOOL)available {
    return _FileStreamID != NULL;
}

- (void) errorForOSStatus: (OSStatus) status error: (NSError *__autoreleasing *) outError {
    if (status != noErr && outError != NULL) {
        *outError = [NSError errorWithDomain: NSOSStatusErrorDomain code: status userInfo: nil];
    }
}

- (BOOL) openFileStreamWithFileTypeHint: (AudioFileTypeID) fileTypeHint error: (NSError *__autoreleasing *) error {
    OSStatus status = AudioFileStreamOpen( (__bridge void * _Nullable)(self), CYFileStreamPropertyListener,  CYFileStreamPacketsCallBack, fileTypeHint, &_FileStreamID);
    if (status != noErr) {
        _FileStreamID = NULL;
    }
    [self errorForOSStatus: status error: error];
    return status == noErr;
}

#pragma mark - actions
- (NSData *)fetchMagicCookie {
    
    UInt32 cookieSize;
    Boolean writable;
    OSStatus status = AudioFileStreamGetPropertyInfo(_FileStreamID, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
    
    if (status != noErr) {
        return nil;
    }
    
    void *cookieData = malloc(cookieSize);
    status = AudioFileStreamGetProperty(_FileStreamID, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
    if (status != noErr) {
        return nil;
    }
    
    NSData *cookie = [NSData dataWithBytes: cookieData length: cookieSize];
    free(cookieData);
    
    return cookie;
}

- (BOOL)parseData:(NSData *)data error:(NSError *__autoreleasing *)error {
    if (self.readyToProducePackets && _packetDuration == 0) {
        [self errorForOSStatus: -1 error: error];
        return NO;
    }
    OSStatus status = AudioFileStreamParseBytes(_FileStreamID, (UInt32)[data length], [data bytes], _discontinuous ? kAudioFileStreamParseFlag_Discontinuity : 0);
    [self errorForOSStatus: status error: error];
    return status == noErr;
}

- (SInt64)seekToTime:(NSTimeInterval *)time {
    
    SInt64 seekByteOffset;
    
    SInt64 seekToPacket = floor(*time / _packetDuration);
    SInt64 outDataByteOffset;
    UInt32 ioFlags = 0;
    SInt64 approximateSeekOffset = _dataOffset + (*time / _duration) * _audioDataByteCount;
   
    OSStatus status = AudioFileStreamSeek(_FileStreamID, seekToPacket, &outDataByteOffset, &ioFlags);
    if (status == noErr && !(ioFlags & kAudioFileStreamSeekFlag_OffsetIsEstimated)) {
        *time -= ((approximateSeekOffset - _dataOffset) - outDataByteOffset) * 8.0 / _bitRate;
        seekByteOffset = outDataByteOffset + _dataOffset;
    } else {
        _discontinuous = YES;
        seekByteOffset = approximateSeekOffset;
    }
    return seekByteOffset;
}

#pragma mark - 回调
- (void) calculateBitRate {
    if (_packetDuration &&  _ProcessedPacketCount > BitRateEstimationMinPackets && _ProcessedPacketCount <= BitRateEstimationMaxPackets) {
        double averagePacketByteSize = _ProcessedPacketSizeTotal / _ProcessedPacketCount;
        _bitRate = 8.0 * averagePacketByteSize / _packetDuration;
    }
}

// packet的长度
- (void) calculatePacketDuration {
    if (_format.mSampleRate > 0) {
        _packetDuration = _format.mFramesPerPacket / _format.mSampleRate;
    }
}

// 总长度
- (void) calculateDuration {
    if (_fileSize > 0 && _bitRate > 0) {
        _duration = ((_fileSize - _dataOffset) * 8.0) / _bitRate;
    }
}

// listener的回调
- (void)handleAudioFileStreamProperty:(AudioFileStreamPropertyID)propertyID {
    if (propertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
        _readyToProducePackets = YES;
        _discontinuous = YES;
        
        UInt32 sizeOfUInt32 = sizeof(_maxPacketSize);
        OSStatus status = AudioFileStreamGetProperty(_FileStreamID, kAudioFileStreamProperty_PacketSizeUpperBound, &sizeOfUInt32, &_maxPacketSize);
        if (status != noErr || _maxPacketSize == 0) {
            status = AudioFileStreamGetProperty(_FileStreamID, kAudioFileStreamProperty_MaximumPacketSize, &sizeOfUInt32, &_maxPacketSize);
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(fileStreamReadyToProducePackets:)]) {
            [_delegate fileStreamReadyToProducePackets: self];
        }
    } else if (propertyID == kAudioFileStreamProperty_DataOffset) {
        UInt32 offsetSize = sizeof(_dataOffset);
        AudioFileStreamGetProperty(_FileStreamID, kAudioFileStreamProperty_DataOffset, &offsetSize, &_dataOffset);
        _audioDataByteCount = _fileSize - _dataOffset;
        [self calculateDuration];
    } else if (propertyID == kAudioFileStreamProperty_DataFormat) {
        UInt32 asbdSize = sizeof(_format);
        AudioFileStreamGetProperty(_FileStreamID, kAudioFileStreamProperty_DataFormat, &asbdSize, &_format);
        [self calculatePacketDuration];
    } else if (propertyID == kAudioFileStreamProperty_FormatList) {
        Boolean outWriteable;
        UInt32 formatListSize;
        OSStatus status = AudioFileStreamGetPropertyInfo(_FileStreamID, kAudioFileStreamProperty_FormatList, &formatListSize, &outWriteable);
        if (status == noErr) {
            AudioFormatListItem *formatList = malloc(formatListSize);
            OSStatus status = AudioFileStreamGetProperty(_FileStreamID, kAudioFileStreamProperty_FormatList, &formatListSize, formatList);
            if (status == noErr) {
                UInt32 supportedFormatsSize;
                status = AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &supportedFormatsSize);
                if (status != noErr) {
                    free(formatList);
                    return;
                }
                
                UInt32 supportedFormatCount = supportedFormatsSize / sizeof(OSType);
                OSType *supportedFormats = (OSType *)malloc(supportedFormatsSize);
                status = AudioFormatGetProperty(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &supportedFormatsSize, supportedFormats);
                if (status != noErr) {
                    free(formatList);
                    free(supportedFormats);
                    return;
                }
                
                for (int i = 0; i * sizeof(AudioFormatListItem) < formatListSize; i += sizeof(AudioFormatListItem)) {
                    AudioStreamBasicDescription format = formatList[i].mASBD;
                    for (UInt32 j = 0; j < supportedFormatCount; j++) {
                        if (format.mFormatID == supportedFormats[j]) {
                            _format = format;
                            [self calculatePacketDuration];
                            break;
                        }
                    }
                }
                free(supportedFormats);
            }
            free(formatList);
        }
    }
}

// 读取成功的回调
- (void)handleAudioFIleStreamPackets:(const void *)packets numberOfBytes:(UInt32)numberOfBytes numberOfPackets:(UInt32)numberOfPackets packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions {
    
    if (_discontinuous) {
        _discontinuous = NO;
    }
    
    if (numberOfBytes == 0 || numberOfPackets == 0) {
        return;
    }
    
    BOOL deletePackDesc = NO;
    if (packetDescriptions == NULL) {
        deletePackDesc = YES;
        UInt32 packetSize = numberOfBytes / numberOfPackets;
        AudioStreamPacketDescription *descriptions = (AudioStreamPacketDescription *)malloc(sizeof(AudioStreamPacketDescription) *numberOfPackets);
        
        for (int i = 0; i < numberOfPackets; i++) {
            UInt32 packetOffset = packetSize * i;
            descriptions[i].mStartOffset = packetOffset;
            descriptions[i].mVariableFramesInPacket = 0;
            if (i == numberOfPackets - 1) {
                descriptions[i].mDataByteSize = numberOfBytes - packetOffset;
            } else {
                descriptions[i].mDataByteSize = packetSize;
            }
        }
        packetDescriptions = descriptions;
    }
    
    NSMutableArray *parsedDataArray = [NSMutableArray new];
    for (int i = 0; i < numberOfPackets; ++i) {
        SInt64 packetOffset = packetDescriptions[i].mDataByteSize;
        
        // 在此传递解析完的数据
        CYParasedData *parasedData = [CYParasedData parasedAudioDataWithBytes: packets + packetOffset packetDesciption: packetDescriptions[i]];
        [parsedDataArray addObject: parasedData];
        
        if (_ProcessedPacketCount < BitRateEstimationMaxPackets) {
            _ProcessedPacketSizeTotal += parasedData.packetDesciption.mDataByteSize;
            _ProcessedPacketCount += 1;
            [self calculateBitRate];
            [self calculateDuration];
        }
    }
    
    // 代理回调
    [_delegate fileStream: self DataParsed: parsedDataArray];
    
    if (deletePackDesc) {
        free(packetDescriptions);
    }
}
@end
