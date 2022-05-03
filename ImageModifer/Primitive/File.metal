//
//  File.metal
//  ImageModifer
//
//  Created by Renjun Li on 2022/4/23.
//

#include <metal_stdlib>
using namespace metal;

struct v2f
{
    float4 position [[position]];
    half3 color;
};

v2f vertex myVertexShader(uint vertexId [[vertex_id]],
                          device const float3* positions [[buffer(0)]],
                          device const float3* colors [[buffer(1)]] )
{
    v2f o;
    o.position = float4( positions[ vertexId ], 1.0 );
    o.color = half3 ( colors[ vertexId ] );
    return o;
}

half4 fragment myFragmentShader(v2f in [[stage_in]] )
{
    return half4( in.color, 1.0 );
}


typedef struct
{
    float4 position;
    float2 texCoords;
} VertexIn;


typedef struct
{
    float4 position [[position]];
    float2 texCoords;
}VertexOut;



vertex VertexOut showImageVertexShader(const device VertexIn* vertexArray [[buffer(0)]],
                                unsigned int vid  [[vertex_id]]){

    VertexOut verOut;
    verOut.position = vertexArray[vid].position;
    verOut.texCoords = vertexArray[vid].texCoords;
    return verOut;

}


fragment float4 showImageFragmentShader(
                                VertexOut vertexIn [[stage_in]],
                                        texture2d <float> colorTexture [[ texture(0) ]]
                             )
{
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 color = colorTexture.sample(textureSampler, vertexIn.texCoords);
    return color;

}
