//
//  ScaleFilter.metal
//  ImageModifer
//
//  Created by Renjun Li on 2022/5/16.
//

#include <metal_stdlib>
using namespace metal;

constant int smooth = 1000;

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
