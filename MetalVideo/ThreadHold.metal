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


fragment
float4 saturationSamplingShader(RasterizerData input [[ stage_in ]],
                           texture2d<half> colorTexture [[ texture(0) ]]) {
    // 创建采样器
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    half4 colorSample = colorTexture.sample(textureSampler, input.textureCoordinate);
    float rgbMax = max(colorSample.r, max(colorSample.g, colorSample.b)) * 255;
    float rgbMin = min(colorSample.r, min(colorSample.g, colorSample.b)) * 255;
    float L = (rgbMax + rgbMin) * 0.5;
    float S = 128 * (rgbMax -rgbMin) / (510 - (rgbMax + rgbMin));
    if (L < 128) {
        S = 128 * (rgbMax -rgbMin) / (rgbMax + rgbMin);
    }
    float saturation = 50; //(0, 100)
    float k = saturation * 128.0 / 100.0;
    float alpha = k;
    if (k >= 0) {
        alpha = (k + S) >= 128 ? S : (128 - k);
        alpha = 128 * 128 / alpha - 128;
    }
    float3 RGBN = float3(colorSample.rgb) + (float3(colorSample.rgb) - float3(L)) * alpha / 128;
    return float4(RGBN, 1.0);
}

constant float SquareSize = 63.0 / 512.0;
constant float stepSize = 0.0; //0.5 / 512.0;

fragment float4
lutSamplingShader(RasterizerData input [[stage_in]], // stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
               texture2d<float> normalTexture [[ texture(0) ]], // texture表明是纹理数据，LYFragmentTextureIndexNormal是索引
               texture2d<float> lookupTableTexture [[ texture(1) ]]) // texture表明
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear); // sampler是采样器
    float4 textureColor = normalTexture.sample(textureSampler, input.textureCoordinate); //正常的纹理颜色
    
    float blueColor = textureColor.b * 63.0; // 蓝色部分[0, 63] 共64种
    
    float2 quad1; // 第一个正方形的位置, 假如blueColor=22.5，则y=22/8=2，x=22-8*2=6，即是第2行，第6个正方形；（因为y是纵坐标）
    quad1.y = floor(floor(blueColor) * 0.125);
    quad1.x = floor(blueColor) - (quad1.y * 8.0);
    
    float2 quad2; // 第二个正方形的位置，同上。注意x、y坐标的计算，还有这里用int值也可以，但是为了效率使用float
    quad2.y = floor(ceil(blueColor) * 0.125);
    quad2.x = ceil(blueColor) - (quad2.y * 8.0);
    
    float2 texPos1; // 计算颜色(r,b,g)在第一个正方形中对应位置
    /*
     quad1是正方形的坐标，每个正方形占纹理大小的1/8，即是0.125，所以quad1.x * 0.125是算出正方形的左下角x坐标
     stepSize这里设置为0，可以忽略；
     SquareSize是63/512，一个正方形小格子在整个图片的纹理宽度
     */
    
    texPos1.x = (quad1.x * 0.125) + stepSize + (SquareSize * textureColor.r);
    texPos1.y = (quad1.y * 0.125) + stepSize + (SquareSize * textureColor.g);
    
    float2 texPos2; // 同上
    texPos2.x = (quad2.x * 0.125) + stepSize + (SquareSize * textureColor.r);
    texPos2.y = (quad2.y * 0.125) + stepSize + (SquareSize * textureColor.g);
    
    float4 newColor1 = lookupTableTexture.sample(textureSampler, texPos1); // 正方形1的颜色值
    float4 newColor2 = lookupTableTexture.sample(textureSampler, texPos2); // 正方形2的颜色值
    
    float4 newColor = mix(newColor1, newColor2, fract(blueColor)); // 根据小数点的部分进行mix
    return float4(newColor.rgb, textureColor.w); //不修改alpha值
}
