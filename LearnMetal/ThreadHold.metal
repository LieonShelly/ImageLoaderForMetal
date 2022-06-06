//
//  ThreadHold.metal
//  LearnMetal
//
//  Created by Renjun Li on 2022/6/6.
//  Copyright © 2022 loyinglin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#import "LYShaderTypes.h"

typedef struct
{
    float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点
    float2 textureCoordinate; // 纹理坐标，会做插值处理
    
} RasterizerData;

vertex
RasterizerData threadHoldVertexShader(uint vertexID [[ vertex_id]],
                                 constant LYVertex *vertextArray[[ buffer(0) ]]) {
    RasterizerData out;
    out.clipSpacePosition = vertextArray[vertexID].position;
    out.textureCoordinate = vertextArray[vertexID].textureCoordinate;
    return out;
}

fragment
float4 threadHoldSamplingShader(RasterizerData input [[ stage_in ]],
                           texture2d<half> colorTexture [[ texture(0) ]]) {
    // 创建采样器
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    half4 colorSample = colorTexture.sample(textureSampler, input.textureCoordinate);
    half gray = (colorSample.r + colorSample.g + colorSample.b) / 3;
    gray = gray < 0.5 ? 0 : 1;

    float brightness = 0;
    float contrast = 1;
    float saturation = 0.5;
    float3 color = float4(colorSample).rgb + float3(brightness);
    float3 color1 = (color - float3(0.5)) *  contrast + float3(0.5);
    float luminanceWeighting = 0.2125 * colorSample.r + 0.7154 * colorSample.g + 0.0721 * colorSample.b;
    float3 color2 = float3(dot(color1.rgb, luminanceWeighting));
    return float4(mix(color2, color1.rgb, saturation), colorSample.w);
}

fragment
float4 brightContrastSaturationSamplingShader(RasterizerData input [[ stage_in ]],
                           texture2d<half> colorTexture [[ texture(0) ]]) {
    // 创建采样器
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    half4 colorSample = colorTexture.sample(textureSampler, input.textureCoordinate);
    half gray = (colorSample.r + colorSample.g + colorSample.b) / 3;
    gray = gray < 0.5 ? 0 : 1;

    float brightness = 0;
    float contrast = 1;
    float saturation = 0.5;
    float3 color = float4(colorSample).rgb + float3(brightness);
    float3 color1 = (color - float3(0.5)) *  contrast + float3(0.5);
    float luminanceWeighting = 0.2125 * colorSample.r + 0.7154 * colorSample.g + 0.0721 * colorSample.b;
    float3 color2 = float3(dot(color1.rgb, luminanceWeighting));
    return float4(mix(color2, color1.rgb, saturation), colorSample.w);
}
