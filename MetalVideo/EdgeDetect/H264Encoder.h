//
//  H264Encoder.h
//  MetalVideo
//
//  Created by Renjun Li on 2022/6/15.
//  Copyright © 2022 renjun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <VideoToolBox/VideoToolBox.h>

NS_ASSUME_NONNULL_BEGIN

@interface H264Encoder : NSObject
- (void)encodeFrame:(CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END
