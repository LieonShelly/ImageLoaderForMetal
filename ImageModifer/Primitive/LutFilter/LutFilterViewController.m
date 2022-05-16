//
//  LutFilterViewController.m
//  ImageModifer
//
//  Created by Renjun Li on 2022/5/12.
//

#import "LutFilterViewController.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

typedef struct {
    vector_float4 position;
    vector_float2 textureCoordinate;
} VertexIn;


@interface LutFilterViewController ()<MTKViewDelegate>

@property(nonatomic, strong) MTKView *mtkView;
@property(nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;
@property(nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, assign) vector_uint2 viewportSize;
@property (nonatomic, strong) id <MTLBuffer> rgbVertices;

@property (nonatomic, strong) id <MTLBuffer> alphaVertices;

@property (nonatomic, strong) id<MTLBuffer> convertMatrix;

@property (nonatomic, assign) float intensity;

@property (nonatomic, assign) NSInteger numVertices;
@property(nonatomic, strong) id<MTLBuffer> pVertexPositionsBuffer;
@property(nonatomic, strong) id<MTLTexture> sourceTexture;
@property(nonatomic, strong) id<MTLTexture> lutTexture;


@end

@implementation LutFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}


- (void)setup {
    [self setupMTKView];
    [self setupUIView];
    [self setupCommandQueue];
    [self buildBuffer];
    [self setupPipeline];
}

- (void)buildBuffer {
    float heightScaling = 1.0;
    float widthScaling = 1.0;
    VertexIn vertexArrayData[] = {
        { {-widthScaling,  heightScaling, 0.0, 1.0}, {0.0, 0.0} },
        { { widthScaling,  heightScaling, 0.0, 1.0}, {1.0, 0.0} },
        { {-widthScaling, -heightScaling, 0.0, 1.0}, {0.0, 1.0} },
        { { widthScaling, -heightScaling, 0.0, 1.0}, {1.0, 1.0} },
    };

    _pVertexPositionsBuffer = [_device newBufferWithBytes:vertexArrayData length:sizeof(vertexArrayData) options:0];
    self.numVertices = sizeof(vertexArrayData) / sizeof(VertexIn);
    
    // 获取源文件位置
    NSString * imgpath = [[NSBundle mainBundle]pathForImageResource:@"picture-this.jpeg"];
    MTKTextureLoader *loader = [[MTKTextureLoader alloc]initWithDevice:self.device];
    NSData *imageData = [NSData dataWithContentsOfFile: imgpath];
    _sourceTexture = [loader newTextureWithData:imageData options:nil error:nil];
    
    // 获取lut图片位置
    NSString * lutImgPth = [[NSBundle mainBundle]pathForImageResource:@"youhualut.png"];
    NSData *lutImageData = [NSData dataWithContentsOfFile: lutImgPth];
    _lutTexture = [loader newTextureWithData:lutImageData options:nil error:nil];
    
    _intensity = 0.0;
}

- (void)setupMTKView {
    _device = MTLCreateSystemDefaultDevice();
    _mtkView = [[MTKView alloc]initWithFrame:self.view.frame device:_device];
    _mtkView.layer.backgroundColor = NSColor.grayColor.CGColor;
    _mtkView.delegate = self;
    self.mtkView.layer.opaque = false;
    [self.view addSubview:self.mtkView];
    self.viewportSize = (vector_uint2){self.view.frame.size.width, self.view.frame.size.height};
}

- (void)setupUIView {
    NSSlider *progress = [NSSlider sliderWithTarget:self action:@selector(sliderAction:)];
    [progress setMaxValue:1.0];
    [progress setMinValue:0.0];
    progress.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:progress];
    
}

- (void)sliderAction:(NSSlider*)slider {
    float progress = slider.floatValue;
    self.intensity = progress;
}

- (void)setupCommandQueue {
    _commandQueue = [_device newCommandQueue];
}

- (void)setupPipeline {
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunc = [defaultLibrary newFunctionWithName:@"lutVertex"];
    id<MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"lutFragment"];
    
    MTLRenderPipelineDescriptor *pipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDesc.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
    pipelineDesc.vertexFunction = vertexFunc;
    pipelineDesc.fragmentFunction = fragmentFunc;
   self.pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDesc error:nil];
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    MTLRenderPassDescriptor *renderDesc = view.currentRenderPassDescriptor;
    renderDesc.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    
    id <MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderDesc];
    [commandEncoder setViewport:(MTLViewport){0, 0, self.viewportSize.x, self.viewportSize.y, -1, 1}];
    [commandEncoder setRenderPipelineState:self.pipelineState];
    [commandEncoder setVertexBuffer:self.pVertexPositionsBuffer offset:0 atIndex:0];

    [commandEncoder setFragmentTexture:_sourceTexture atIndex:0];
    [commandEncoder setFragmentTexture:_lutTexture atIndex:1];
    // 设置常量，对应shader中 constant 类型
    [commandEncoder setFragmentBytes:&_intensity length:sizeof(_intensity) atIndex:0];
    
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:self.numVertices];
    [commandEncoder endEncoding];
    
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
    
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    self.viewportSize = (vector_uint2){size.width, size.height};
}
@end
