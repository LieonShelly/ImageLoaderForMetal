//
//  AVasetReader.m
//  LearnMetal
//
//  Created by Renjun Li on 2022/6/4.
//  Copyright © 2022 loyinglin. All rights reserved.
//

#import "AssetReader.h"

@implementation AssetReader
{
    AVAssetReaderTrackOutput *readerVideoTrackOutput;
    AVAssetReader   *assetReader;
    NSURL *videoUrl;
    NSLock *lock;
    AVAsset *inputAsset;
    CGSize previewOutSize;
    BOOL initedDecoder;
    BOOL released;
    AVAssetTrack *videoTrack;
    float fps;
}

- (instancetype)initWithUrl:(NSURL *)url {
    self = [super init];
    videoUrl = url;
    lock = [[NSLock alloc] init];
    [self customInit];
    return self;
}

- (void)customInit {
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    inputAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:inputOptions];
    __weak typeof(self) weakSelf = self;
    [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = nil;
            AVKeyValueStatus tracksStatus = [self->inputAsset statusOfValueForKey:@"tracks" error:&error];
            if (tracksStatus != AVKeyValueStatusLoaded)
            {
                NSLog(@"error %@", error);
                return;
            }
            [weakSelf processWithAsset:self->inputAsset startTime: 1];
        });
    }];
}

- (void)processWithAsset:(AVAsset *)asset startTime:(double)startTime
{
    [lock lock];
    NSLog(@"processWithAsset");
    NSError *error = nil;
    assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    
    [outputSettings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [outputSettings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
    readerVideoTrackOutput.alwaysCopiesSampleData = NO;
    [assetReader addOutput:readerVideoTrackOutput];

    CMTime pos = CMTimeMakeWithSeconds(startTime, inputAsset.duration.timescale);
    assetReader.timeRange = CMTimeRangeMake(pos, CMTimeMakeWithSeconds(1, 1));
    if ([assetReader startReading] == NO)
    {
        NSLog(@"Error reading from file at URL: %@", asset);
    }
    [lock unlock];
}

- (CMSampleBufferRef)readBufferWithStartTime:(double)startTime {
    [lock lock];
    CMSampleBufferRef sampleBufferRef = nil;
    
    if (readerVideoTrackOutput) {
        sampleBufferRef = [readerVideoTrackOutput copyNextSampleBuffer];
    }
    
    if (assetReader && assetReader.status == AVAssetReaderStatusCompleted) {
        NSLog(@"customInit");
        readerVideoTrackOutput = nil;
        assetReader = nil;
        [self customInit];
    }
    
    [lock unlock];
    return sampleBufferRef;
}
@end

