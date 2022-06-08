//
//  SobelShader.metal
//  LearnMetal
//
//  Created by Renjun Li on 2022/5/30.
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
RasterizerData sobelVertexShader(uint vertexID [[ vertex_id]],
                                 constant LYVertex *vertextArray[[ buffer(0) ]]) {
    RasterizerData out;
    out.clipSpacePosition = vertextArray[vertexID].position;
    out.textureCoordinate = vertextArray[vertexID].textureCoordinate;
    return out;
}

fragment
float4 sobelSamplingShader(RasterizerData input [[ stage_in ]],
                           texture2d<half> colorTexture [[ texture(0) ]]) {
    // 创建采样器
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    half4 colorSample = colorTexture.sample(textureSampler, input.textureCoordinate);
    return float4(colorSample);
}

constant half sobelStep = 2.0;
constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722); // 把rgba转成亮度值

kernel
void sobelkernel(texture2d<half, access::read> sourceTexture [[ texture(0) ]],
                 texture2d<half, access::write> destTexture [[ texture(1) ]], uint2 grid [[thread_position_in_grid]]) {
    /*
     
     行数     9个像素          位置
     上     | * * * |      | 左 中 右 |
     中     | * * * |      | 左 中 右 |
     下     | * * * |      | 左 中 右 |
     
     */
    half4 topLeft = sourceTexture.read(uint2(grid.x - sobelStep, grid.y - sobelStep)); // 左上
    half4 top = sourceTexture.read(uint2(grid.x, grid.y - sobelStep)); // 上
    half4 topRight = sourceTexture.read(uint2(grid.x + sobelStep, grid.y - sobelStep)); // 右上
    half4 centerLeft = sourceTexture.read(uint2(grid.x - sobelStep, grid.y)); // 中左
    half4 centerRight = sourceTexture.read(uint2(grid.x + sobelStep, grid.y)); // 中右
    half4 bottomLeft = sourceTexture.read(uint2(grid.x - sobelStep, grid.y + sobelStep)); // 下左
    half4 bottom = sourceTexture.read(uint2(grid.x, grid.y + sobelStep)); // 下中
    half4 bottomRight = sourceTexture.read(uint2(grid.x + sobelStep, grid.y + sobelStep)); // 下右
    
    half4 h = -topLeft - 2.0 * top - topRight + bottomLeft + 2.0 * bottom + bottomRight; // 横方向差别
    half4 v = -bottom - 2.0 * centerLeft - topLeft + bottomRight + 2.0 * centerRight + topRight; // 竖方向差别
    
    half  grayH  = dot(h.rgb, kRec709Luma); // 转换成亮度
    half  grayV  = dot(v.rgb, kRec709Luma); // 转换成亮度
    
    // sqrt(h^2 + v^2)，相当于求点到(h, v)的距离，所以可以用length
//    half color = length(half2(grayH, grayV));

//    destTexture.write(half4(color, color, color, 1.0), grid); // 写回对应纹理
    half4 color = sourceTexture.read(grid);//length(half2(grayH, grayV));
//
    destTexture.write(color, grid); // 写回对应纹理
}
