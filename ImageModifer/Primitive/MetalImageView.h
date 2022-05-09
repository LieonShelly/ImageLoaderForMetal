//
//  MetalImageView.h
//  ImageModifer
//
//  Created by Renjun Li on 2022/5/4.
//

#import <Cocoa/Cocoa.h>
@import MetalKit;

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, HobenRenderingResizingMode) {
    HobenRenderingResizingModeScale = 0,
    HobenRenderingResizingModeAspectFit,
    HobenRenderingResizingModeAspectFill,
};

@protocol HobenMetalImageViewDataSource <NSObject>

- (CVMetalTextureRef)currentPixelBuffer;

@end


@interface MetalImageView : NSView
@property (nonatomic, assign) CVMetalTextureRef pixelBuffer;
@property (nonatomic, assign) CGSize videoSize;
@property (nonatomic, weak  ) id <HobenMetalImageViewDataSource> dataSource;
@end

NS_ASSUME_NONNULL_END
