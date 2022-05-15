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

vertex
VertexOut lutVertex(const device VertexIn* vertexArray [[buffer(0)]],
unsigned int vid  [[vertex_id]])
{
    VertexOut o;
    o.position = vertexArray[vid ].position;
    o.texCoords = vertexArray[vid].texCoords;
    return o;
}

fragment
float4 lutFragment(VertexOut input [[ stage_in ]],
                   texture2d<float> normalTexture [[ texture(0) ]],
                   texture2d<float> lookupTableTexture [[ texture(1) ]],
                   constant float &intensity [[ buffer(0) ]]) {
    const sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 textureColor = normalTexture.sample(textureSampler, input.texCoords);
    
    float blueColor = textureColor.b * 63; // 蓝色部分[0, 63] 共64种
    
    float2 quad1; //第一个正方形的位置
    quad1.y = floor(floor(blueColor) * 0.125);
    quad1.x = floor(blueColor) - (quad1.y * 8.0);
    
    float2 quad2; // 第二个正方形的位置
    quad2.y = floor(ceil(blueColor) * 0.125);
    quad2.x = ceil(blueColor) - quad2.y * 8.0;
    
    // 该像素点相对于小方格的位置（取中间点，所以乘以63再加上0.5）
    float squareX = textureColor.r * 63 + stepSize;
    float squareY = textureColor.g * 63 + stepSize;
    
    float2 texPos1; // 正方形1对应像素点相对于LUT图的位置
    texPos1.x = quad1.x * 64 + squareX;
    texPos1.y = quad1.y * 64 + squareY;
    
    float2 textPos2;
    textPos2.x = quad2.x * 64 + squareX;
    textPos2.y = quad2.y * 64 + squareY;
    
    float4 newColor1 = lookupTableTexture.sample(textureSampler, texPos1 / 512); // 正方形1的颜色值
    float4 newColor2 = lookupTableTexture.sample(textureSampler, textPos2 / 512); // 正方形2的颜色值
    
    float4 newColor = mix(newColor1, newColor2, fract(blueColor)); // 根据小数点的部分进行mix
    return mix(textureColor, float4(newColor.rgb, textureColor.a), intensity);
}
