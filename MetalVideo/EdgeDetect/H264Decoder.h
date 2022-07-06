//
//  H264Decoder.h
//  MetalVideo
//
//  Created by Renjun Li on 2022/6/21.
//  Copyright © 2022 renjun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface H264Decoder : NSObject
- (void)onInputStart;
- (void)updateFrame:(void(^)(CVPixelBufferRef))callback;
- (CVPixelBufferRef)updateFrame;
@end

NS_ASSUME_NONNULL_END
