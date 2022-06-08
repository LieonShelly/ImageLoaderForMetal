//
//  AVassetReader.h
//  LearnMetal
//
//  Created by Renjun Li on 2022/6/4.
//  Copyright © 2022 loyinglin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetReader : NSObject

- (instancetype)initWithUrl:(NSURL*)url;
- (CMSampleBufferRef)readBuffer;
@end

NS_ASSUME_NONNULL_END
