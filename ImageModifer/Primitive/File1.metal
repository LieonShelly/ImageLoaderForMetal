//
//  File1.metal
//  ImageModifer
//
//  Created by Renjun Li on 2022/5/8.
//

#include <metal_stdlib>
using namespace metal;
#import "HobenShaderType.h"

typedef struct {
    float4 vertexPosition [[ position ]];
    float2 textureCoorRgb;
    float2 textureColorAlpha;
} RasterizerData;

vertex
RasterizerData vertexShader(uint vertexId [[ vertex_id ]],
                            constant Vertex *rgbVertexArray [[ buffer(0) ]],
                            constant Vertex *alphaVertexArray [[ buffer(1) ]]
                            ) {
    RasterizerData out;
    out.vertexPosition = rgbVertexArray[vertexId].position;
    out.textureCoorRgb = rgbVertexArray[vertexId].textureCoordinate;
    out.textureColorAlpha = alphaVertexArray[vertexId].textureCoordinate;
    return out;
}


float3 rgbFromYuv(float2 textureCoor,
                  texture2d<float> textureY,
                  texture2d<float> textureUV,
                  constant ConvertMartix *converMartix
                  ) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    // why
    float3 yuv = float3(textureY.sample(textureSampler, textureCoor).r,
                        textureY.sample(textureSampler, textureCoor).rg);
    return  converMartix->matrix * (yuv + converMartix->offset);
}


fragment
float4 fragmentShader(RasterizerData input [[ stage_in]],
                      texture2d <float> textureY [[ texture(0) ]],
                      texture2d <float> textureUV [[ texture(1) ]],
                       constant ConvertMartix *convertMatrix [[ buffer(0) ]]) {
    float3 rgb = rgbFromYuv(input.textureCoorRgb, textureY, textureUV, convertMatrix);
    float alpha = rgbFromYuv(input.textureColorAlpha, textureY, textureUV, convertMatrix).r;
    return  float4(rgb, alpha);
}
