//
//  ViewController.m
//  LearnMetal
//
//  Created by loyinglin on 2018/6/21.
//  Copyright © 2018年 loyinglin. All rights reserved.
//
@import MetalKit;
@import GLKit;

#import "LYShaderTypes.h"
#import "SkyBoxViewController.h"

@interface SkyBoxViewController () <MTKViewDelegate>

// view
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) IBOutlet UISwitch *rotationEyePosition;
@property (nonatomic, strong) IBOutlet UISwitch *rotationEyeLookat;

@property (nonatomic, strong) IBOutlet UISlider *slider;

@property (assign, nonatomic) GLKVector3 eyePosition;
@property (assign, nonatomic) GLKVector3 lookAtPosition;
@property (assign, nonatomic) GLKVector3 upVector;

// data
@property (nonatomic, assign) vector_uint2 viewportSize;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLDepthStencilState> depthStencilState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, strong) id<MTLBuffer> vertices;
@property (nonatomic, assign) NSUInteger verticesCount;


@end

@implementation SkyBoxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds];
    self.mtkView.device = MTLCreateSystemDefaultDevice();
    [self.view insertSubview:self.mtkView atIndex:0];
    self.mtkView.delegate = self;
    self.viewportSize = (vector_uint2){self.mtkView.drawableSize.width, self.mtkView.drawableSize.height};
    
    // 观察参数的初始化
    self.eyePosition = GLKVector3Make(0, 0, 0);
    self.lookAtPosition = GLKVector3Make(0, 0, 0);
    self.upVector = GLKVector3Make(0, 1, 0);
    
    [self customInit];
}

- (void)customInit {
    [self setupPipeline];
    [self setupVertex];
    [self setupTexture];
}

-(void)setupPipeline {
    id<MTLLibrary> defaultLibrary = [self.mtkView.device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"skyBoxVertexShader"];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"skyBoxSamplingShader"];
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
    self.pipelineState = [self.mtkView.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                         error:NULL];
    self.commandQueue = [self.mtkView.device newCommandQueue];
}

- (void)setupVertex {
    static const LYVertex quadVertices[] =
    {
        // 上面
        {{-6.0f, 6.0f, 6.0f, 1.0f},      {1.0f, 0.0f, 0.0f},       {0.0f, 2.0f/6}},//左上 0
        {{-6.0f, -6.0f, 6.0f, 1.0f},     {0.0f, 0.0f, 1.0f},       {0.0f, 3.0f/6}},//左下 2
        {{6.0f, -6.0f, 6.0f, 1.0f},      {1.0f, 1.0f, 1.0f},       {1.0f, 3.0f/6}},//右下 3

        {{-6.0f, 6.0f, 6.0f, 1.0f},      {1.0f, 0.0f, 0.0f},       {0.0f, 2.0f/6}},//左上 0
        {{6.0f, 6.0f, 6.0f, 1.0f},       {0.0f, 1.0f, 0.0f},       {1.0f, 2.0f/6}},//右上 1
        {{6.0f, -6.0f, 6.0f, 1.0f},      {1.0f, 1.0f, 1.0f},       {1.0f, 3.0f/6}},//右下 3


        // 下面
        {{-6.0f, 6.0f, -6.0f, 1.0f},     {1.0f, 0.0f, 0.0f},       {0.0f, 4.0f/6}},//左上 4
        {{6.0f, 6.0f, -6.0f, 1.0f},      {0.0f, 1.0f, 0.0f},       {1.0f, 4.0f/6}},//右上 5
        {{6.0f, -6.0f, -6.0f, 1.0f},     {1.0f, 1.0f, 1.0f},       {1.0f, 3.0f/6}},//右下 7

        {{-6.0f, 6.0f, -6.0f, 1.0f},     {1.0f, 0.0f, 0.0f},       {0.0f, 4.0f/6}},//左上 4
        {{-6.0f, -6.0f, -6.0f, 1.0f},    {0.0f, 0.0f, 1.0f},       {0.0f, 3.0f/6}},//左下 6
        {{6.0f, -6.0f, -6.0f, 1.0f},     {1.0f, 1.0f, 1.0f},       {1.0f, 3.0f/6}},//右下 7
        
        // 左面
        {{-6.0f, 6.0f, 6.0f, 1.0f},      {1.0f, 0.0f, 0.0f},       {0.0f, 1.0f/6}},//左上 0
        {{-6.0f, -6.0f, 6.0f, 1.0f},     {0.0f, 0.0f, 1.0f},       {1.0f, 1.0f/6}},//左下 2
        {{-6.0f, 6.0f, -6.0f, 1.0f},     {1.0f, 0.0f, 0.0f},       {0.0f, 2.0f/6}},//左上 4

        {{-6.0f, -6.0f, 6.0f, 1.0f},     {0.0f, 0.0f, 1.0f},       {1.0f, 1.0f/6}},//左下 2
        {{-6.0f, 6.0f, -6.0f, 1.0f},     {1.0f, 0.0f, 0.0f},       {0.0f, 2.0f/6}},//左上 4
        {{-6.0f, -6.0f, -6.0f, 1.0f},    {0.0f, 0.0f, 1.0f},       {1.0f, 2.0f/6}},//左下 6


        // 右面
        {{6.0f, 6.0f, 6.0f, 1.0f},       {0.0f, 1.0f, 0.0f},       {1.0f, 0.0f/6}},//右上 1
        {{6.0f, -6.0f, 6.0f, 1.0f},      {1.0f, 1.0f, 1.0f},       {0.0f, 0.0f/6}},//右下 3
        {{6.0f, 6.0f, -6.0f, 1.0f},      {0.0f, 1.0f, 0.0f},       {1.0f, 1.0f/6}},//右上 5

        {{6.0f, -6.0f, 6.0f, 1.0f},      {1.0f, 1.0f, 1.0f},       {0.0f, 0.0f/6}},//右下 3
        {{6.0f, 6.0f, -6.0f, 1.0f},      {0.0f, 1.0f, 0.0f},       {1.0f, 1.0f/6}},//右上 5
        {{6.0f, -6.0f, -6.0f, 1.0f},     {1.0f, 1.0f, 1.0f},       {0.0f, 1.0f/6}},//右下 7
        
        // 前面
        {{-6.0f, -6.0f, 6.0f, 1.0f},     {0.0f, 0.0f, 1.0f},       {0.0f, 4.0f/6}},//左下 2
        {{6.0f, -6.0f, 6.0f, 1.0f},      {1.0f, 1.0f, 1.0f},       {1.0f, 4.0f/6}},//右下 3
        {{6.0f, -6.0f, -6.0f, 1.0f},     {1.0f, 1.0f, 1.0f},       {1.0f, 5.0f/6}},//右下 7

        {{-6.0f, -6.0f, 6.0f, 1.0f},     {0.0f, 0.0f, 1.0f},       {0.0f, 4.0f/6}},//左下 2
        {{-6.0f, -6.0f, -6.0f, 1.0f},    {0.0f, 0.0f, 1.0f},       {0.0f, 5.0f/6}},//左下 6
        {{6.0f, -6.0f, -6.0f, 1.0f},     {1.0f, 1.0f, 1.0f},       {1.0f, 5.0f/6}},//右下 7

        // 后面
        {{-6.0f, 6.0f, 6.0f, 1.0f},      {1.0f, 0.0f, 0.0f},       {1.0f, 5.0f/6}},//左上 0
        {{6.0f, 6.0f, 6.0f, 1.0f},       {0.0f, 1.0f, 0.0f},       {0.0f, 5.0f/6}},//右上 1
        {{6.0f, 6.0f, -6.0f, 1.0f},      {0.0f, 1.0f, 0.0f},       {0.0f, 6.0f/6}},//右上 5

        {{-6.0f, 6.0f, 6.0f, 1.0f},      {1.0f, 0.0f, 0.0f},       {1.0f, 5.0f/6}},//左上 0
        {{-6.0f, 6.0f, -6.0f, 1.0f},     {1.0f, 0.0f, 0.0f},       {1.0f, 6.0f/6}},//左上 4
        {{6.0f, 6.0f, -6.0f, 1.0f},      {0.0f, 1.0f, 0.0f},       {0.0f, 6.0f/6}},//右上 5
        
        /*
        // 上面的四个点
        {{-6.0f, 6.0f, 6.0f, 1.0f},      {1.0f, 0.0f, 0.0f},       {0.0f, 1.0f}},//左上 0
        {{6.0f, 6.0f, 6.0f, 1.0f},       {0.0f, 1.0f, 0.0f},       {1.0f, 1.0f}},//右上 1
        {{-6.0f, -6.0f, 6.0f, 1.0f},     {0.0f, 0.0f, 1.0f},       {0.0f, 0.0f}},//左下 2
        {{6.0f, -6.0f, 6.0f, 1.0f},      {1.0f, 1.0f, 1.0f},       {1.0f, 0.0f}},//右下 3
        
        // 下面的四个点
        {{-6.0f, 6.0f, -6.0f, 1.0f},     {1.0f, 0.0f, 0.0f},       {0.0f, 1.0f}},//左上 4
        {{6.0f, 6.0f, -6.0f, 1.0f},      {0.0f, 1.0f, 0.0f},       {1.0f, 1.0f}},//右上 5
        {{-6.0f, -6.0f, -6.0f, 1.0f},    {0.0f, 0.0f, 1.0f},       {0.0f, 0.0f}},//左下 6
        {{6.0f, -6.0f, -6.0f, 1.0f},     {1.0f, 1.0f, 1.0f},       {1.0f, 0.0f}},//右下 7
         */
        
    };
    self.vertices = [self.mtkView.device newBufferWithBytes:quadVertices
                                                 length:sizeof(quadVertices)
                                                options:MTLResourceStorageModeShared];
    
    
    self.verticesCount = sizeof(quadVertices) / sizeof(LYVertex);
}

- (void)setupTexture {
    UIImage *image = [UIImage imageNamed:@"image"];
    if(!image)
    {
        NSLog(@"Failed to create the image");
        return ;
    }
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor textureCubeDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm size:image.size.width mipmapped:NO];
    self.texture = [self.mtkView.device newTextureWithDescriptor:textureDescriptor];
    
    Byte *imageBytes = [self loadImage:image];
    NSInteger pixels = image.size.width * image.size.width;
    
    if (imageBytes) {
        for (int i = 0; i < 6; i++) {
            [self.texture replaceRegion:MTLRegionMake2D(0, 0, image.size.width, image.size.width)
                            mipmapLevel:0
                                  slice:i
                              withBytes:imageBytes + (i * pixels * 4)
                            bytesPerRow:4 * (NSInteger)image.size.width bytesPerImage:pixels * 4];
        }
        free(imageBytes);
        imageBytes = NULL;
    }
    
    
}

- (Byte *)loadImage:(UIImage *)image {
    // 1获取图片的CGImageRef
    CGImageRef spriteImage = image.CGImage;
    
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    Byte * spriteData = (Byte *) calloc(width * height * 4, sizeof(Byte)); //rgba共4个byte
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    return spriteData;
}

- (matrix_float4x4)getMetalMatrixFromGLKMatrix:(GLKMatrix4)matrix {
    matrix_float4x4 ret = (matrix_float4x4) {
        simd_make_float4(matrix.m00, matrix.m01, matrix.m02, matrix.m03),
        simd_make_float4(matrix.m10, matrix.m11, matrix.m12, matrix.m13),
        simd_make_float4(matrix.m20, matrix.m21, matrix.m22, matrix.m23),
        simd_make_float4(matrix.m30, matrix.m31, matrix.m32, matrix.m33),
    };
    return ret;
}

- (void)setupMatrixWithEncoder:(id<MTLRenderCommandEncoder>)renderEncoder {
    static float angle = 0, angleLook = 0;
    if (self.rotationEyePosition.on) {
        angle += self.slider.value;
    }
    if (self.rotationEyeLookat.on) {
        angle += self.slider.value;
    }
    self.eyePosition = GLKVector3Make(2.0 * sinf(angle), 2.0 * cosf(angle), 0.0);
    // 调整观察的位置
    self.lookAtPosition = GLKVector3Make(2.0f * sinf(angleLook),
                                         2.0f * cosf(angleLook),
                                         2.0f);
    CGSize size = self.view.bounds.size;
    float aspect = fabs(size.width / size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85), aspect, 0.1f, 20.f);// 投影变换矩阵
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeLookAt(
                                                      self.eyePosition.x,
                                                      self.eyePosition.y,
                                                      self.eyePosition.z,
                                                      self.lookAtPosition.x,
                                                      self.lookAtPosition.y,
                                                      self.lookAtPosition.z,
                                                      self.upVector.x,
                                                      self.upVector.y,
                                                      self.upVector.z);
    LYMatrix matrix = {[self getMetalMatrixFromGLKMatrix:projectionMatrix], [self getMetalMatrixFromGLKMatrix:modelViewMatrix]};
    [renderEncoder setVertexBytes:&matrix length:sizeof(matrix) atIndex:1];
}


#pragma mark - delegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    self.viewportSize = (vector_uint2){size.width, size.height};
}

- (void)drawInMTKView:(MTKView *)view {
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    if(renderPassDescriptor != nil)
    {
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.6, 0.6, 1.0f);
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, self.viewportSize.x, self.viewportSize.y, -1.0, 1.0 }];
        [renderEncoder setRenderPipelineState:self.pipelineState];
        
        [self setupMatrixWithEncoder:renderEncoder];
        
        [renderEncoder setVertexBuffer:self.vertices
                                offset:0
                               atIndex:0];
        
        [renderEncoder setFragmentTexture:self.texture
                                  atIndex:0];
        
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.verticesCount];
        
        [renderEncoder endEncoding];
        
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    [commandBuffer commit];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

