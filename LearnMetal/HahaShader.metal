//
//  shaders.metal
//  LearnMetal
//
//  Created by loyinglin on 2018/6/21.
//  Copyright © 2018年 loyinglin. All rights reserved.
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
hahaVertexShader(uint vertexID [[ vertex_id ]], // vertex_id是顶点shader每次处理的index，用于定位当前的顶点
             constant LYVertex *vertexArray [[ buffer(0) ]],
                 constant float &radius  [[ buffer(1) ]]) { // buffer表明是缓存数据，0是索引
    float OX = 0;
    float OY = 0;
    float CX =  vertexArray[vertexID].position.x + OX;
    float CY =  vertexArray[vertexID].position.y + OY;
    float dis = sqrt((CX - OX) * (CX - OX) + (CY - OY) * (CY - OY));
    float newCX = dis * (CX - OX) / radius + OX;
    float newCY = dis * (CY - OY) / radius + OY;
    
    RasterizerData out;
    out.clipSpacePosition = float4(newCX, newCY, 0, 1);
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

fragment float4
hahaSamplingShader(RasterizerData input [[stage_in]], // stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
               texture2d<half> colorTexture [[ texture(0) ]]) // texture表明是纹理数据，0是索引
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear); // sampler是采样器
    
    half4 colorSample = colorTexture.sample(textureSampler, input.textureCoordinate); // 得到纹理对应位置的颜色
    
    return float4(colorSample);
}


// 获取灰度图
vertex
RasterizerData grayVertexShader(uint vertexID [[ vertex_id]],
                 constant LYVertex *vertexArray [[ buffer(0)]]) {
    RasterizerData out;
    out.clipSpacePosition = vertexArray[vertexID].position;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

fragment
float4 graySampling(RasterizerData input [[ stage_in ]], // stage_in 表示这个数据来自光栅化（光栅化是顶点处理之后的步骤，业务层无法修改）
                    texture2d<half> colorTexture [[ texture(0) ]]) { // texture表明是纹理数据，0是索引
    // 采样器
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    
    // 获取纹理对应的颜色
    half4 colorSample = colorTexture.sample(textureSampler, input.textureCoordinate);
    return float4(colorSample);
}

constant half3 kRec708Luma = half3(0.2126, 0.7152, 0.0722); // 把rgb抓换为亮度值

// 给计算管道使用，处理之后的图像，交给片段着色器渲染出来
kernel
void getGrayKernel(texture2d<half, access::read> sourceTexure [[texture(0)]],
                texture2d<half, access::write> destTexture  [[texture(1)]],
                uint2 grid [[thread_position_in_grid ]]) {
    if(grid.x < destTexture.get_width() && grid.y <= destTexture.get_height()) {
        half4 color = sourceTexure.read(grid);
        half gray = dot(color.rgb, kRec708Luma);
        destTexture.write(half4(gray, gray, gray, 1.0), grid);
    }
}
