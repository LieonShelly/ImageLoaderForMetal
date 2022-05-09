//
//  MetalImageView.m
//  ImageModifer
//
//  Created by Renjun Li on 2022/5/4.
//

#import "MetalImageView.h"
#import "HobenShaderType.h"
#import <AVFoundation/AVFoundation.h>

@interface MetalImageView()<MTKViewDelegate>
@property(nonatomic, strong) MTKView *mtkView;
@property(nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;
@property(nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, assign) vector_uint2 viewportSize;
@property (nonatomic, strong) id <MTLBuffer> rgbVertices;

@property (nonatomic, strong) id <MTLBuffer> alphaVertices;

@property (nonatomic, strong) id<MTLBuffer> convertMatrix;

@property (nonatomic, assign) NSInteger numVertices;


@end

@implementation MetalImageView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}


- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [self setupMTKView];
    [self setupCommandQueue];
    [self setupPipeline];
}

- (void)setupMTKView {
    _mtkView = [[MTKView alloc] init];
    _device = MTLCreateSystemDefaultDevice();
    _mtkView.device = _device;
    _mtkView.delegate = self;
    _mtkView.layer.opaque = false;
    [self addSubview: _mtkView];
    CVMetalTextureCacheCreate(NULL, NULL, _device, NULL, &_textureCache);
}

- (void)setupCommandQueue {
    _commandQueue = [_device newCommandQueue];
}

- (void)setupPipeline {
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunc = [defaultLibrary newFunctionWithName:@"vertextShader"];
    id<MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"fragmentShader"];
    
    MTLRenderPipelineDescriptor *pipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDesc.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
    pipelineDesc.vertexFunction = vertexFunc;
    pipelineDesc.fragmentFunction = fragmentFunc;
   self.pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDesc error:nil];
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    MTLRenderPassDescriptor *renderDesc = view.currentRenderPassDescriptor;
    CVMetalTextureRef pixelBuffer = [self.dataSource currentPixelBuffer];
    self.videoSize = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer) / 2, CVPixelBufferGetHeight(pixelBuffer) / 2);
    
    id<MTLTexture> textureY = [self textureWithPixelBuffer:pixelBuffer pixelFormat:MTLPixelFormatR8Unorm planeIndex:0];
    id<MTLTexture> textureUV = [self textureWithPixelBuffer:pixelBuffer pixelFormat:MTLPixelFormatRG8Unorm planeIndex:1];
    [self setupMatrixWithPixelBuffer:pixelBuffer];
    if (pixelBuffer) {
        CFRelease(pixelBuffer);
    }
    if (!renderDesc || !textureY || !textureUV) {
        [commandBuffer commit];
        return;
    }
    
    renderDesc.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    [self setupVertexWithRenderDesc:renderDesc];
    id <MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderDesc];
    [commandEncoder setViewport:(MTLViewport){0, 0, self.viewportSize.x, self.viewportSize.y, -1, 1}];
    [commandEncoder setRenderPipelineState:self.pipelineState];
    [commandEncoder setVertexBuffer:self.rgbVertices offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:self.alphaVertices offset:0 atIndex:1];
    [commandEncoder setFragmentBuffer:self.convertMatrix offset:0 atIndex:0];
    [commandEncoder setFragmentTexture:textureY atIndex:0];
    [commandEncoder setFragmentTexture:textureUV atIndex:1];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:self.numVertices];
    [commandEncoder endEncoding];
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    self.viewportSize = (vector_uint2){size.width, size.height};
}

- (void)setupMatrixWithPixelBuffer:(CVMetalTextureRef)pixelBuffer { // 设置好转换的矩阵
    if (self.convertMatrix) {
        return;
    }
            
    OSType pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    BOOL isFullYUVRange = (pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange ? YES : NO);
    
    CFTypeRef colorAttachments = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
    ConvertMartix preferredConversion = HobenYUVColorConversion601FullRange;
    
    if (colorAttachments != NULL) {
        if (CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
            if (isFullYUVRange) {
                preferredConversion = HobenYUVColorConversion601FullRange;
            } else {
                preferredConversion = HobenYUVColorConversion601;
            }
        } else {
            preferredConversion = HobenYUVColorConversion709;
        }
    } else {
        if (isFullYUVRange) {
            preferredConversion = HobenYUVColorConversion601FullRange;
        } else {
            preferredConversion = HobenYUVColorConversion601;
        }
    }
    self.convertMatrix = [self.mtkView.device newBufferWithBytes:&preferredConversion
                                                          length:sizeof(ConvertMartix)
                                                         options:MTLResourceStorageModeShared];
}

- (id <MTLTexture>)textureWithPixelBuffer:(CVMetalTextureRef)pixelBuffer pixelFormat:(MTLPixelFormat)pixelFormat planeIndex:(NSInteger)planeIndex {
    id<MTLTexture> texture = NULL;
    size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex);
    size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex);
    CVMetalTextureRef textureRef = NULL;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, _textureCache, pixelBuffer, NULL, pixelFormat, width, height, planeIndex, &textureRef);
    if (status) {
        texture = CVMetalTextureGetTexture(textureRef);
        CFRelease(textureRef);
    } else {
        texture = nil;
    }
    return texture;
}


- (void)setupVertexWithRenderDesc:(MTLRenderPassDescriptor *)renderDesc {
    if (self.rgbVertices && self.alphaVertices) {
        return;
    }
    float heightScaling = 1.0;
    float widthScaling = 1.0;
    CGSize drawableSize = CGSizeMake(renderDesc.colorAttachments[0].texture.width, renderDesc.colorAttachments[0].texture.height);
    CGRect bounds = CGRectMake(0, 0, drawableSize.width, drawableSize.height);
    CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(self.videoSize, bounds);
    HobenRenderingResizingMode mode = CGSizeEqualToSize(self.videoSize, CGSizeZero) ? HobenRenderingResizingModeScale : HobenRenderingResizingModeAspectFill;
    switch (mode) {
        case HobenRenderingResizingModeScale:
            heightScaling = 1.0;
            widthScaling = 1.0;
            break;
            
        case HobenRenderingResizingModeAspectFit:
            widthScaling = insetRect.size.width / drawableSize.width;
            heightScaling = insetRect.size.height / drawableSize.height;
            break;
            
        case HobenRenderingResizingModeAspectFill:
            widthScaling = drawableSize.height / insetRect.size.height;
            heightScaling = drawableSize.width / insetRect.size.width;
            break;
    }
    Vertex alphaVertices[] = {
        // 顶点坐标 x, y, z, w  --- 纹理坐标 x, y
        { {-widthScaling,  heightScaling, 0.0, 1.0}, {0.0, 0.0} },
        { { widthScaling,  heightScaling, 0.0, 1.0}, {0.5, 0.0} },
        { {-widthScaling, -heightScaling, 0.0, 1.0}, {0.0, 1.0} },
        { { widthScaling, -heightScaling, 0.0, 1.0}, {0.5, 1.0} },
    };
    
    CGFloat offset = .5f;
    
    Vertex rgbVertices[] = {
        // 顶点坐标 x, y, z, w  --- 纹理坐标 x, y
        { {-widthScaling,  heightScaling, 0.0, 1.0}, {0.0 + offset, 0.0} },
        { { widthScaling,  heightScaling, 0.0, 1.0}, {0.5 + offset, 0.0} },
        { {-widthScaling, -heightScaling, 0.0, 1.0}, {0.0 + offset, 1.0} },
        { { widthScaling, -heightScaling, 0.0, 1.0}, {0.5 + offset, 1.0} },
    };
    self.rgbVertices = [_device newBufferWithBytes:rgbVertices length:sizeof(rgbVertices) options:MTLResourceStorageModeShared];
    self.numVertices = sizeof(rgbVertices) / sizeof(Vertex);
    self.alphaVertices = [_device newBufferWithBytes:alphaVertices length:sizeof(alphaVertices) options:MTLResourceStorageModeShared];
}


@end
