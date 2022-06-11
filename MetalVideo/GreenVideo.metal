//
//  GreenVideo.metal
//  LearnMetal
//
//  Created by Renjun Li on 2022/6/2.
//  Copyright © 2022 loyinglin. All rights reserved.
//

#include <metal_stdlib>

#import "LYShaderTypes.h"

using namespace metal;

typedef struct
{
    float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点
    
    float2 textureCoordinate; // 纹理坐标，会做插值处理
    
} RasterizerData;

vertex RasterizerData // 返回给片元着色器的结构体
greenVideoVertexShader(uint vertexID [[ vertex_id ]], // vertex_id是顶点shader每次处理的index，用于定位当前的顶点
             constant LYVertex *vertexArray [[ buffer(0) ]]) { // buffer表明是缓存数据，0是索引
    RasterizerData out;
    out.clipSpacePosition = vertexArray[vertexID].position;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

constant float3 greenMaskColor = float3(0.0, 1.0, 0.0);// 过滤掉绿色 // r, g, b\

fragment float4
greenVideoSamplingShader(RasterizerData input [[ stage_in ]],
                                texture2d<float> normalTextureY [[ texture(0)]],
                                texture2d<float> normalTextureUV [[ texture(1)]],
                                constant LYConvertMatrix *convertMatrix [[ buffer(0) ]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    // 正常视频读取出来的图像，yuv颜色空间
    float3 normalVideoYUV = float3(normalTextureY.sample(textureSampler, input.textureCoordinate).r,
                             normalTextureUV.sample(textureSampler, input.textureCoordinate).rg);
    // yuv转成rgb
    float3 normalVideoRGB = convertMatrix->matrix * (normalVideoYUV + convertMatrix->offset);
    return float4(normalVideoRGB, 1);
}
