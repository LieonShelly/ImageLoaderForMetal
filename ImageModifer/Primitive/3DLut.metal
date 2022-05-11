//
//  3DLut.metal
//  ImageModifer
//
//  Created by Renjun Li on 2022/5/12.
//

#include <metal_stdlib>
using namespace metal;

typedef struct
{
    float4 position; //
    float2 texCoords;
} VertexIn;


typedef struct
{
    float4 position [[position]];
    float2 texCoords;
}VertexOut;


constant float stepSize = 0.5;

fragment
float4 lutFragment(VertexIn input [[ stage_in ]],
                   texture2d<float> normalTexture [[ texture(0) ]],
                   texture2d<float> lookupTableTexture [[ texture(1) ]],
                   constant float &intensity [[ buffer(0) ]]) {
    const sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 textureColor = normalTexture.sample(textureSampler, input.texCoords);
    
    float blueColor = textureColor.b * 63; // 蓝色部分[0, 63] 共64种
    
    float2 quad1; //第一个正方形的位置
    // ...
    float2 quad2; // 第二个正方形的位置
    // ..
    
    // 该像素点相对于小方格的位置
    float squreX = textureColor.r * 63 + stepSize;
    float squreY = textureColor.g * 63 + stepSize;
    
    float2 texPos1;
    // ...
    
    float2 textPos2;
    
    // ...
    float4 newColor1 = lookupTableTexture.sample(textureSampler, texPos1 / 512);
    float4 newColor2 = lookupTableTexture.sample(textureSampler, textPos2 / 512);
    
    float4 newColor = mix(newColor1, newColor2, fract(blueColor));
    return mix(textureColor, float4(newColor.rgb, textureColor.a), intensity);
}
