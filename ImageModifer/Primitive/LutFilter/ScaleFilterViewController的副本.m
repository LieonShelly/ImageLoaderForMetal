//
//  ScaleFilterViewController.m
//  ImageModifer
//
//  Created by Renjun Li on 2022/5/16.
//

#import "ScaleFilterViewController.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <math.h>

typedef struct {
    vector_float2 position;
    vector_float2 textureCoordinate;
} VertexIn;

@interface ScaleFilterViewController ()<MTKViewDelegate>
@property(nonatomic, strong) MTKView *mtkView;
@property(nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;
@property (nonatomic, assign) vector_uint2 viewportSize;
@property (nonatomic, strong) id<MTLBuffer> pTextureCoordBuffer;
@property (nonatomic, assign) NSInteger numVertices;
@property(nonatomic, strong) id<MTLBuffer> pVertexPositionsBuffer;
@property(nonatomic, strong) id<MTLTexture> sourceTexture;
@property (nonatomic, assign) float scale;
@end

@implementation ScaleFilterViewController

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
    vector_float2 textureCoordArrayData[] = {
        { 0.0, 0.0 },
        { 1.0, 0.0 },
        { 0.0, 1.0 },
        { 1.0, 1.0 },
    };
    
    vector_float2 vertexArrayData[] = {
         {-widthScaling,  heightScaling },
         { widthScaling,  heightScaling },
         {-widthScaling, -heightScaling },
         { widthScaling, -heightScaling },
    };

    _pVertexPositionsBuffer = [_device newBufferWithBytes:vertexArrayData length:sizeof(vertexArrayData) options:0];
    self.numVertices = sizeof(vertexArrayData) / sizeof(vector_float2);
    _pTextureCoordBuffer = [_device newBufferWithBytes:textureCoordArrayData length:sizeof(textureCoordArrayData) options:0];
    
    // 获取源文件位置
    NSString * imgpath = [[NSBundle mainBundle]pathForImageResource:@"picture-this.jpeg"];
    MTKTextureLoader *loader = [[MTKTextureLoader alloc]initWithDevice:self.device];
    NSData *imageData = [NSData dataWithContentsOfFile: imgpath];
    _sourceTexture = [loader newTextureWithData:imageData options:nil error:nil];
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
    self.scale = progress;
}


- (void)setupCommandQueue {
    _commandQueue = [_device newCommandQueue];
}

- (void)setupPipeline {
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunc = [defaultLibrary newFunctionWithName:@"zoomVertex"];
    id<MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"zoomFragment"];
    
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
    [commandEncoder setVertexBuffer:self.pTextureCoordBuffer offset:0 atIndex:2];

    [commandEncoder setFragmentTexture:_sourceTexture atIndex:0];
    // 设置常量，对应shader中 constant 类型
    simd_float4x4 martrix = {
        .columns[0] = simd_make_float4(1, 0, 0, 0),
        .columns[1] = simd_make_float4(0, 1, 0, 0),
        .columns[2] = simd_make_float4(0, 0, 1, 0),
        .columns[3] = simd_make_float4(1, 0, 0, 1)
    };

//    [commandEncoder setVertexBytes:&martrix length:sizeof(martrix) atIndex:1];
    [commandEncoder setVertexBytes:&_scale length:sizeof(_scale) atIndex:1];
    
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:self.numVertices];
    [commandEncoder endEncoding];
    
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
    
   
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    self.viewportSize = (vector_uint2){size.width, size.height};
}
@end
