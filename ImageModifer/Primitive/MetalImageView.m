//
//  MetalImageView.m
//  ImageModifer
//
//  Created by Renjun Li on 2022/5/4.
//

#import "MetalImageView.h"
#import "HobenShaderType.h"

@interface MetalImageView()<MTKViewDelegate>
@property(nonatomic, strong) MTKView *mtkView;
@property(nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;
@property(nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, assign) vector_uint2 viewportSize;

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
    
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    self.viewportSize = (vector_uint2){size.width, size.height};
}



@end
