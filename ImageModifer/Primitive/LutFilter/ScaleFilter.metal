//
//  ScaleFilter.metal
//  ImageModifer
//
//  Created by Renjun Li on 2022/5/16.
//

#include <metal_stdlib>
using namespace metal;

typedef struct
{
    float4 position [[position]];
    float2 texCoords;
}VertexOut;


vertex
VertexOut zoomVertex(const device float2 *position [[ buffer(0) ]],
                     const device float &scale [[ buffer(1) ]],
                     const device float2 *textCoord [[ buffer(2) ]],
                     uint vid [[ vertex_id ]]) {
    // 将顶点放大
    float2 currentPos = scale * position[vid];
    VertexOut out;
    out.position = float4(currentPos, 0, 1);
    out.texCoords = textCoord[vid];
    return out;
}

fragment
float4 zoomFragment(VertexOut input [[ stage_in ]],
                   texture2d<float> normalTexture [[ texture(0) ]]) {
    const sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 textureColor = normalTexture.sample(textureSampler, input.texCoords);
    return textureColor;
}


vertex
VertexOut translateVertex(const device float2 *position [[ buffer(0) ]],
                     const device float4x4 &martix [[ buffer(1) ]],
                     const device float2 *textCoord [[ buffer(2) ]],
                     uint vid [[ vertex_id ]]) {
    float y = 0.0;
    /**
     simd_float4x4 martrix = {
         .columns[0] = simd_make_float4(1, 0, 0, 0),
         .columns[1] = simd_make_float4(0, 1, 0, 0),
         .columns[2] = simd_make_float4(0, 0, 1, 0),
         .columns[3] = simd_make_float4(0.5, 1.5, 0, 1)
     };

     
     */
//    float4x4 translateMartix =
//    {   {1, 0, 0, 0},
//        {0, 1, 0, x},
//        {0, 0, 1, 0},
//        {0, 0, 0, 1}
//    };
//    float4x4 translateMartix;
//    translateMartix[0][0] = 1;
//    translateMartix[0][1] = 0;
//    translateMartix[0][2] = 0;
//    translateMartix[0][3] = x;
//    
//    translateMartix[1][0] = 0;
//    translateMartix[1][1] = 1;
//    translateMartix[1][2] = 0;
//    translateMartix[1][3] = y;
//    
//    translateMartix[2][0] = 0;
//    translateMartix[2][1] = 0;
//    translateMartix[2][2] = 1;
//    translateMartix[2][3] = 0;
//    
//    translateMartix[3][0] = 0;
//    translateMartix[3][1] = 0;
//    translateMartix[3][2] = 0;
//    translateMartix[3][3] = 1;
    
    
    // 将顶点放大
    float4 currentPos = martix *  float4(position[vid], 0, 1);
    VertexOut out;
    out.position = currentPos;
    out.texCoords = textCoord[vid];
    return out;
}
