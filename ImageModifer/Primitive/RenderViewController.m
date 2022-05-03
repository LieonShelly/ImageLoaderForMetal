//
//  RenderViewController.m
//  ImageModifer
//
//  Created by Renjun Li on 2022/4/22.
//

#import "RenderViewController.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

typedef struct {
    vector_float4 position;
    vector_float2 textureCoordinate;
} VertexIn;

@interface RenderViewController() <MTKViewDelegate>
@property(nonatomic, strong) MTKView *mtkView;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) id<MTLCommandBuffer> commandBuffer;
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLBuffer> pVertexPositionsBuffer;
@property(nonatomic, strong) id<MTLBuffer> pVertexColorsBuffer;
@property(nonatomic, strong) id<MTLRenderPipelineState> renderPipeState;
@property(nonatomic, strong) id<MTLLibrary> shaderLibrary;
@property(nonatomic, strong) id<MTLTexture> sourceTexture;
@property (nonatomic, assign) vector_uint2 viewportSize;
@property (nonatomic, assign) NSUInteger numVertices;

@end

@implementation RenderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialize];
    [self buildShader];
    [self buildBuffers];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    self.viewportSize = (vector_uint2){size.width, size.height};
}

- (void)drawInMTKView:(MTKView *)view {
    [self draw];
}

- (void)buildShader {
    MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
    _shaderLibrary = [_device newDefaultLibrary];
    desc.vertexFunction = [_shaderLibrary newFunctionWithName:@"showImageVertexShader"];
    desc.fragmentFunction = [_shaderLibrary newFunctionWithName:@"showImageFragmentShader"];
    desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    NSError *error;
    _renderPipeState = [_device newRenderPipelineStateWithDescriptor:desc error:&error];
    if (error) {
        NSLog(@"error: %@", error.description);
    }
}

- (void)buildBuffers {
    // Create my Vertex Array x，y，z，w。
    float heightScaling = 1.0;
    float widthScaling = 1.0;
    VertexIn vertexArrayData[] = {
        { {-widthScaling,  heightScaling, 0.0, 1.0}, {0.0, 0.0} },
        { { widthScaling,  heightScaling, 0.0, 1.0}, {1.0, 0.0} },
        { {-widthScaling, -heightScaling, 0.0, 1.0}, {0.0, 1.0} },
        { { widthScaling, -heightScaling, 0.0, 1.0}, {1.0, 1.0} },
    };
    const float colors[] = {
        1.0, 0.3f, 0.2f,
        0.8f, 1.0, 0.0f,
        0.8f, 0.0f, 1.0,
    };
    _pVertexPositionsBuffer = [_device newBufferWithBytes:vertexArrayData length:sizeof(vertexArrayData) options:0];
    _pVertexColorsBuffer = [_device newBufferWithBytes:colors length:sizeof(colors) options:0];
    
    NSString * imgpath = [[NSBundle mainBundle]pathForImageResource:@"test.jpeg"];
    MTKTextureLoader *loader = [[MTKTextureLoader alloc]initWithDevice:self.device];
    NSData *imageData = [NSData dataWithContentsOfFile: imgpath];
    _sourceTexture = [loader newTextureWithData:imageData options:nil error:nil];

    self.numVertices = sizeof(vertexArrayData) / sizeof(VertexIn);

}

- (void)initialize {
    _device = MTLCreateSystemDefaultDevice();
    if (_device == nil) {
        NSLog(@"dont support metal!");
        return;
    }
    _commandQueue = [_device newCommandQueue];
    _mtkView = [[MTKView alloc]initWithFrame:self.view.frame device:_device];
    _mtkView.clearColor = MTLClearColorMake(0, 1, 0, 1);
    _mtkView.delegate = self;
    [self.view addSubview:_mtkView];
    _commandBuffer =  [_commandQueue commandBuffer];
    self.viewportSize = (vector_uint2){self.view.frame.size.width, self.view.frame.size.height};
}

- (void)draw {
    id<MTLCommandBuffer> pCmd = [_commandQueue commandBuffer];
    MTLRenderPassDescriptor *pRpd =  [_mtkView currentRenderPassDescriptor];
    id<MTLRenderCommandEncoder> pEnc = [pCmd renderCommandEncoderWithDescriptor:pRpd];
    [pEnc setViewport:(MTLViewport){0, 0, self.viewportSize.x, self.viewportSize.y, -1, 1}];

    [pEnc setRenderPipelineState:_renderPipeState];
    [pEnc setVertexBuffer:_pVertexPositionsBuffer offset:0 atIndex:0];
    [pEnc setFragmentTexture:_sourceTexture atIndex:0];
    [pEnc drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:_numVertices];
    [pEnc endEncoding];
    
    [pCmd presentDrawable:_mtkView.currentDrawable];
    [pCmd commit];
}

@end
