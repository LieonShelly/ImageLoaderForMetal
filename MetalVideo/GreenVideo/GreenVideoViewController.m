//
//  GreenVideoViewController.m
//  LearnMetal
//
//  Created by Renjun Li on 2022/6/4.
//  Copyright © 2022 renjun. All rights reserved.
//

#import "GreenVideoViewController.h"
@import MetalKit;
@import AVFoundation;
#import "LYShaderTypes.h"
#import "AssetReader.h"


@interface GreenVideoViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate, MTKViewDelegate>

// view
@property (nonatomic, strong) MTKView *mtkView;

// reader
@property (nonatomic, strong) AssetReader *greenReader;
@property (nonatomic, strong) AssetReader *normalReader;

// data
@property (nonatomic, assign) vector_uint2 viewportSize;
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;
@property (nonatomic, strong) id<MTLComputePipelineState> computePipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache; //output
@property (nonatomic, strong) id<MTLBuffer> vertices;
@property (nonatomic, assign) NSUInteger numVertices;

@property (nonatomic, strong) id<MTLBuffer> convertMatrix;
@end

@implementation GreenVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupMtkView];
    [self setupMatrix];
    [self setupPipeline];
    [self setupVertex];
    [self setupReader];
    
    CADisplayLink * link = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderAction:)];
    [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)renderAction:(CADisplayLink*)displayLink {
    
    float actualFramesPerSecond =  1 / (displayLink.targetTimestamp - displayLink.timestamp);

}

- (void)setupReader {
    self.normalReader = [[AssetReader alloc] initWithUrl:[[NSBundle mainBundle] URLForResource:@"2263.MP4" withExtension:nil]];
}

- (void)setupMtkView {
    self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds];
    self.mtkView.device = MTLCreateSystemDefaultDevice(); // 获取默认的device
    [self.view insertSubview:self.mtkView atIndex:0];
    self.mtkView.translatesAutoresizingMaskIntoConstraints = false;
    self.mtkView.delegate = self;
    self.viewportSize = (vector_uint2){self.mtkView.drawableSize.width, self.mtkView.drawableSize.height};
    self.mtkView.preferredFramesPerSecond = 10;
    CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_textureCache); // TextureCache的创建
}

- (void)setupPipeline {
    id<MTLLibrary> defaultLibrary = [self.mtkView.device newDefaultLibrary]; // .metal
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"greenVideoVertexShader"]; // 顶点shader，vertexShader是函数名
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"greenVideoSamplingShader"]; // 片元shader，samplingShader是函数名
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc]init];
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
    
    // 创建图形渲染管道
    self.renderPipelineState = [self.mtkView.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:NULL];
    // 获取渲染队列
    self.commandQueue = [self.mtkView.device newCommandQueue];
}

- (void)setupVertex {
    const LYVertex quadVertices[] =
    {   // 顶点坐标，分别是x、y、z、w；    纹理坐标，x、y；
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0, -1.0, 0.0, 1.0 },  { 0.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        { {  1.0,  1.0, 0.0, 1.0 },  { 1.f, 0.f } },
    };
    self.vertices = [self.mtkView.device newBufferWithBytes:quadVertices
                                                     length:sizeof(quadVertices)
                                                    options:MTLResourceStorageModeShared]; // 创建顶点缓存
    self.numVertices = sizeof(quadVertices) / sizeof(LYVertex); // 顶点个数
}


- (void)setupMatrix {
    matrix_float3x3 kColorConversion601FullRangeMatrix = (matrix_float3x3) {
        (simd_float3){1.0,    1.0,    1.0},
        (simd_float3){0.0,    -0.343, 1.765},
        (simd_float3){1.4,    -0.711, 0.0},
    };
    vector_float3 kColorConversion601FullRangeOffset = (vector_float3){ -(16.0/255.0), -0.5, -0.5}; // 这个是偏移
    LYConvertMatrix matrix;
    // 设置参数
    matrix.matrix = kColorConversion601FullRangeMatrix;
    matrix.offset = kColorConversion601FullRangeOffset;
    
    self.convertMatrix = [self.mtkView.device newBufferWithBytes:&matrix
                                                          length:sizeof(LYConvertMatrix)
                                                         options:MTLResourceStorageModeShared];

}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    self.viewportSize = (vector_uint2){size.width, size.height};
}


- (void)drawInMTKView:(MTKView *)view {
    // 每次渲染都要单独创建一个CommandBuffer
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    // MTLRenderPassDescriptor描述一系列attachments的值，类似GL的FrameBuffer；同时也用来创建MTLRenderCommandEncoder
    CMSampleBufferRef normalSampleBuffer = [self.normalReader readBufferWithStartTime:1]; // 从LYAssetReader中读取图像数据
    if(renderPassDescriptor && normalSampleBuffer)
    {
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.5, 1.0f); // 设置默认颜色
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor]; //编码绘制指令的Encoder
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, self.viewportSize.x, self.viewportSize.y, -1.0, 1.0 }]; // 设置显示区域
        [renderEncoder setRenderPipelineState:self.renderPipelineState]; // 设置渲染管道，以保证顶点和片元两个shader会被调用
        
        [renderEncoder setVertexBuffer:self.vertices
                                offset:0
                               atIndex:LYVertexInputIndexVertices]; // 设置顶点缓存
        
        [self setupTextureWithEncoder:renderEncoder buffer:normalSampleBuffer];
        
        [renderEncoder setFragmentBuffer:self.convertMatrix
                                  offset:0
                                 atIndex:0];
        
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:self.numVertices]; // 绘制
        
        [renderEncoder endEncoding]; // 结束
        
        [commandBuffer presentDrawable:view.currentDrawable]; // 显示
    }
    
    [commandBuffer commit]; // 提交；
}


- (void)setupTextureWithEncoder:(id<MTLRenderCommandEncoder>)encoder buffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    id<MTLTexture> textureY = nil;
    id<MTLTexture> textureUV = nil;
    // textureY 设置
    {
        size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
        size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
        MTLPixelFormat pixelFormat = MTLPixelFormatR8Unorm; // 这里的颜色格式不是RGBA

        CVMetalTextureRef texture = NULL; // CoreVideo的Metal纹理
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, pixelBuffer, NULL, pixelFormat, width, height, 0, &texture);
        if (status == kCVReturnSuccess) {
            textureY = CVMetalTextureGetTexture(texture);
            CFRelease(texture);
        }
    }
    // textureUV设置
    {
        size_t with = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
        size_t heigt = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
        MTLPixelFormat pixelFormat = MTLPixelFormatRG8Unorm; // 2-8bit的格式
        CVMetalTextureRef texture = NULL;
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, pixelBuffer, NULL, pixelFormat, with, heigt, 1, &texture);
        if (status == kCVReturnSuccess) {
            textureUV = CVMetalTextureGetTexture(texture); // 转成Metal用的纹理
            CFRelease(texture);
        }
    }
    [encoder setFragmentTexture:textureY
                        atIndex:0]; // 设置纹理
    [encoder setFragmentTexture:textureUV
                        atIndex:1]; // 设置纹理
    CFRelease(sampleBuffer);
}
@end

