//
//  CYfile.m
//  CYMusicPlayer
//
//  Created by 杨涛 on 16/6/25.
//  Copyright © 2016年 CookieYang. All rights reserved.
//

#import "CYfile.h"
#import <AudioToolbox/AudioToolbox.h>

static const UInt32 packetPerRead = 15;

@interface CYfile ()
@property (assign , nonatomic) SInt64 packetOffset;
@property (strong , nonatomic) NSFileHandle *fileHandler;

@property (assign , nonatomic) SInt64 dataOffset;
@property (assign , nonatomic) NSTimeInterval packetDuration;
@property (assign , nonatomic) AudioFileID audioFileID;
@end

@implementation CYfile
@synthesize filePath = _filePath;
@synthesize fileType = _fileType;
@synthesize fileSize = _fileSize;
@synthesize duration = _duration;
@synthesize bitRate = _bitRate;
@synthesize format = _format;
@synthesize maxPacketSize = _maxPacketSize;
@synthesize audioDataByteCount = _audioDataByteCount;

#pragma mark - 初始化和销毁
- (instancetype) initWithFilePath:(NSString *)filePath fileType:(AudioFileTypeID)fileType {
    if (self = [super init]) {
        _filePath = filePath;
        _fileType = fileType;
        
        _fileHandler = [NSFileHandle fileHandleForReadingAtPath: _filePath];
        _fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath: _filePath error: nil] fileSize];
        if (_fileHandler && _fileSize > 0) {
            if ([self openAudioFile]) {
                [self fentchFormatInfo];
            }
        } else {
            [_fileHandler closeFile];
        }
    }
    return self;
}

- (void) dealloc {
    [_fileHandler closeFile];
    [self closeAudioFile];
}

#pragma mark - 文件操作
- (BOOL) openAudioFile {
    OSStatus status = AudioFileOpenWithCallbacks((__bridge void *)self, CYAudioFileReadCallBack, NULL, CYAudioFileGetSizeCallBack, NULL, _fileType, &_audioFileID);
    if (status != noErr) {
        _audioFileID = NULL;
        return NO;
    }
    return YES;
}

// 获取格式信息
- (void) fentchFormatInfo {
    UInt32 formatListSize;
    OSStatus status = AudioFileGetPropertyInfo(_audioFileID, kAudioFilePropertyFormatList, &formatListSize, NULL);
    if (status == noErr) {
        BOOL found = NO;
        AudioFormatListItem *formatList = malloc(formatListSize);
        OSStatus status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyFormatList, &formatListSize, formatList);
        if (status == noErr) {
            UInt32 supportedFormatsSize;
            status = AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &supportedFormatsSize);
            if (status != noErr) {
                free(formatList);
                [self closeAudioFile];
                return;
            }
            
            UInt32  supportedFormatCount = supportedFormatsSize / sizeof(OSType);
            OSType *supportedFormats = (OSType *)malloc(supportedFormatsSize);
            status = AudioFormatGetProperty(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &supportedFormatsSize, supportedFormats);
            if (status != noErr) {
                free(formatList);
                free(supportedFormats);
                [self closeAudioFile];
                return;
            }
            
            for (int i = 0; i * sizeof(AudioFormatListItem) < formatListSize; i += sizeof(AudioFormatListItem)) {
                AudioStreamBasicDescription format = formatList[i].mASBD;
                for (UInt32 j = 0; j < supportedFormatCount; j++) {
                    if (format.mFormatID == supportedFormats[j]) {
                        _format = format;
                        found = YES;
                        break;
                    }
                }
            }
            free(supportedFormats);
        }
                 free(formatList);
        
        if (!found) {
            [self closeAudioFile];
            return;
        } else {
            [self calculatePacketDuration];
        }
    }
    
    UInt32 size = sizeof(_bitRate);
    status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyBitRate, &size, &_bitRate);
    if (status != noErr) {
        [self closeAudioFile];
        return;
    }
    
    size = sizeof(_dataOffset);
    status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyDataOffset, &size, &_dataOffset);
    if (status != noErr) {
        [self closeAudioFile];
        return;
    }
    _audioDataByteCount = _fileSize - _dataOffset;
    
    size = sizeof(_duration);
    status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyEstimatedDuration, &size, &_duration);
    if (status != noErr) {
        [self calculateDuration];
    }
    
    size = sizeof(_maxPacketSize);
    status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyPacketSizeUpperBound, &size, &_maxPacketSize);
    if (status != noErr || _maxPacketSize == 0) {
        status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyMaximumPacketSize, &size, &_maxPacketSize);
        if (status != noErr) {
            [self closeAudioFile];
            return;
        }
    }
}

- (NSData *)fentchMagicCookie {
    UInt32 cookieSize;
    OSStatus status = AudioFileGetPropertyInfo(_audioFileID, kAudioFilePropertyMagicCookieData, &cookieSize, NULL);
    if (status != noErr) {
        return nil;
    }
    
    void *cookieData = malloc(cookieSize);
    status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyMagicCookieData, &cookieSize, cookieData);
    if (status != noErr) {
        return nil;
    }
    
    NSData *cookie = [NSData dataWithBytes: cookieData length:cookieSize];
    free(cookieData);
    return cookie;
}

- (NSArray *)parseData:(BOOL *)isEof {
    UInt32 ioNumPackets = packetPerRead;
    UInt32 ioNumBytes = ioNumPackets * _maxPacketSize;
    void *outBuffer = (void *)malloc(ioNumBytes);
    
    AudioStreamPacketDescription *outPacketDescriptions = NULL;
    UInt32 descSize = sizeof(AudioStreamPacketDescription) * ioNumPackets;
    outPacketDescriptions = (AudioStreamPacketDescription *)malloc(descSize);
    OSStatus status = AudioFileReadPacketData(_audioFileID, false, &ioNumBytes, outPacketDescriptions, _packetOffset, &ioNumPackets, outBuffer);
    if (status != noErr) {
        *isEof = status == kAudioFileEndOfFileError;
        free(outBuffer);
        return nil;
    }
    
    if (ioNumBytes == 0) {
        *isEof = YES;
    }
    
    _packetOffset += ioNumPackets;
    
    if (ioNumPackets > 0) {
        NSMutableArray *parsedDataArray = [NSMutableArray new];
        for (int i = 0; i < ioNumPackets; i++) {
            AudioStreamPacketDescription packetDescription;
            if (outPacketDescriptions) {
                packetDescription = outPacketDescriptions[i];
            } else {
                packetDescription.mStartOffset = i * _format.mBytesPerFrame;
                packetDescription.mDataByteSize = _format.mBytesPerFrame;
                packetDescription.mVariableFramesInPacket = _format.mFramesPerPacket;
            }
            CYParasedData *data = [CYParasedData parasedAudioDataWithBytes: outBuffer + packetDescription.mStartOffset packetDesciption:packetDescription];
            if (data) {
                [parsedDataArray addObject: data];
            }
        }
           return parsedDataArray;
    }
    return nil;
}

- (void)seekToTime:(NSTimeInterval)time {
    _packetOffset = floor(time / _packetDuration);
}

- (void) calculatePacketDuration {
    if (_format.mSampleRate > 0) {
        _packetDuration = _format.mFramesPerPacket / _format.mSampleRate;
    }
}

- (void) calculateDuration {
    if (_fileSize > 0 && _bitRate > 0) {
        _duration = ((_fileSize - _dataOffset) * 8) / _bitRate;
    }
}

- (void) closeAudioFile {
    if (self.available) {
        AudioFileClose(_audioFileID);
        _audioFileID = NULL;
    }
}

- (void)close {
    [self closeAudioFile];
}

#pragma mark - callback
- (UInt32) availableDataLengthAtOffset: (SInt64) inPosition maxLength: (UInt32) requestCount {
    if ((inPosition + requestCount) > _fileSize) {
        if (inPosition > _fileSize) {
            return 0;
        } else {
            return (UInt32)(_fileSize - inPosition);
        }
    } else {
        return requestCount;
    }
}

- (NSData *) dataAtOffset: (SInt64) inPosition length: (UInt32) length {
    [_fileHandler seekToFileOffset: inPosition];
    return [_fileHandler readDataOfLength: length];
}


static OSStatus CYAudioFileReadCallBack (void *inClientData,
                                         SInt64 inPosition,
                                         UInt32 requestCount,
                                         void *buffer,
                                         UInt32 *actualCount) {
    
      CYfile *file = (__bridge CYfile *)(inClientData);
    
    *actualCount = [file availableDataLengthAtOffset: inPosition maxLength: requestCount];
    if (*actualCount > 0) {
        NSData *data = [file dataAtOffset: inPosition length: requestCount];
        memcpy(buffer, [data bytes], [data length]);
    }
    
    return noErr;
}

static SInt64 CYAudioFileGetSizeCallBack (void *inClientData) {
    CYfile *file = (__bridge CYfile *)(inClientData);
    return file.fileSize;
}

#pragma mark - property
- (BOOL) available {
    return _audioFileID != NULL;
}
@end
