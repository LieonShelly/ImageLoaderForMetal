//
//  H264Encoder.m
//  MetalVideo
//
//  Created by Renjun Li on 2022/6/15.
//  Copyright © 2022 renjun. All rights reserved.
//

#import "H264Encoder.h"

@interface H264Encoder()
{
    
    VTCompressionSessionRef compressionSession;
    NSInteger frameID;
    NSFileHandle *fileHandle;
}
@end

@implementation H264Encoder

void didCompressionCallback(void * CM_NULLABLE outputCallbackRefCon,
                            void * CM_NULLABLE sourceFrameRefCon,
                            OSStatus status,
                            VTEncodeInfoFlags infoFlags,
                            CM_NULLABLE CMSampleBufferRef sampleBuffer) {
    if (status != 0) {
        return;
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    H264Encoder *encoder = (__bridge H264Encoder*)outputCallbackRefCon;
    bool keyFrame = !CFDictionaryContainsKey(CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0), kCMSampleAttachmentKey_NotSync);
    if (keyFrame) {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        // sps
        size_t sparamterSetSize, sparamterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparamterSetSize, &sparamterSetCount, 0);
        if (statusCode == noErr) {
            // Found sps and now check for pps
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0);
            if (statusCode == noErr) {
                // Found pps
                NSData *sps = [NSData dataWithBytes:sparameterSet length:sparamterSetSize];
                NSData *pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                if (encoder) {
                    [encoder gotSpsPps:sps pps:pps];
                }
            }
        }
        
    }
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr
        ) {
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4; // 返回的NALU数据前sige字节不是0001的startCode，而是大端模式的帧长度length
        //循环获取NALU数据
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            uint32_t NALUnitLength = 0;
            // read the NAL Unit length
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            // 从大端转系统端
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            NSData *data = [[NSData alloc]initWithBytes:(dataPointer + bufferOffset
                                                         + AVCCHeaderLength) length:NALUnitLength];
            [encoder gotEncodedData:data];
            // Move to next NAL unit in block buffer
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
    }
}

- (instancetype)init {
    int32_t with = 1024;
    int32_t height = with * 2;
    if (self = [super init]) {
        NSString *file = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"abc.h264"];
        [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
        [[NSFileManager defaultManager] createFileAtPath:file contents:nil attributes:nil];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:file];
        
        OSStatus status = VTCompressionSessionCreate(NULL, with, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressionCallback, (__bridge void * _Nullable)(self), &compressionSession);
        if (status != 0) {
            return self;
        }
        // 设置实时编码输出
        VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
        
        // 设置帧率
        VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge  CFTypeRef _Nonnull)(@24));
        
        // 设置码率，均值，单位是byte
        int bitRate = with * height * 3 * 4 * 8;
        CFNumberRef bitRateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
        VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, bitRateRef);
        
        // 设置码率，上限，单位是bps
        int bitRateLimit = with * height * 3 * 4;
        CFNumberRef bitRateLimitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRateLimit);
        VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_DataRateLimits, bitRateLimitRef);
        
        // 设置关键帧间隔GOP的大小
        VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef _Nonnull)(@20));
        
        // 准备编码
        VTCompressionSessionPrepareToEncodeFrames(compressionSession);
    }
    return self;
}

- (void)encodeFrame:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // 帧时间，如果设置会导致时间轴过长
    CMTime presentationTimeStamp = CMTimeMake(frameID++, 1000);
    VTEncodeInfoFlags flags;
    OSStatus statusCode = VTCompressionSessionEncodeFrame(compressionSession, imageBuffer, presentationTimeStamp, kCMTimeInvalid, NULL, NULL, &flags);
    if (statusCode != noErr) {
        NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
        VTCompressionSessionInvalidate(compressionSession);
        CFRelease(compressionSession);
        compressionSession = NULL;
        return;
    }
    NSLog(@"H264: VTCompressionSessionEncodeFrame Success");
}

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps {
    NSLog(@"gotSpsPps %d %d", (int)[sps length], (int)[pps length]);
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = sizeof(bytes) - 1;//string literals have implicit trailing '\0'
    NSData *byteHeader = [NSData dataWithBytes:bytes length:length];
    [fileHandle writeData:byteHeader];
    [fileHandle writeData:sps];
    [fileHandle writeData:byteHeader];
    [fileHandle writeData:pps];
}

- (void)gotEncodedData:(NSData*)data {
    NSLog(@"gotEncodedData %d", (int)[data length]);
    if (fileHandle != nil) {
        const char bytes[] = "\x00\x00\x00\x01";
        size_t length = sizeof(bytes) - 1;
        NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
        [fileHandle writeData:ByteHeader];
        [fileHandle writeData:data];
    }
}
@end
