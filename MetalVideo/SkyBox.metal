//
//  SkyBox.metal
//  LearnMetal
//
//  Created by Renjun Li on 2022/6/5.
//  Copyright © 2022 loyinglin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "LYShaderTypes.h"


using namespace metal;

typedef struct
{
    float4 clipSpacePosition [[position]];
    float3 pixelColor;
    float3 textureCoordinate;
    
} RasterizerData;

vertex RasterizerData
skyBoxVertexShader(uint vertexID [[ vertex_id ]],
             constant LYVertex *vertexArray [[ buffer(0) ]],
             constant LYMatrix *matrix [[ buffer(1) ]]) {
    RasterizerData out;
    out.clipSpacePosition = matrix->projectionMatrix * matrix->modelViewMatrix * vertexArray[vertexID].position;
    out.textureCoordinate = vertexArray[vertexID].position.xyz;
    out.pixelColor = vertexArray[vertexID].color;
    
    return out;
}



fragment float4
skyBoxSamplingShader(RasterizerData input [[stage_in]],
               texturecube<half> textureColor [[ texture(0) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    half4 colorTex = textureColor.sample(textureSampler, input.textureCoordinate);
//    half4 colorTex = half4(input.pixelColor.x, input.pixelColor.y, input.pixelColor.z, 1); // 方便调试
    return float4(colorTex);
}
