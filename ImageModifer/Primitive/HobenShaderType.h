//
//  HobenShaderType.h
//  ImageModifer
//
//  Created by Renjun Li on 2022/5/4.
//

#ifndef HobenShaderType_h
#define HobenShaderType_h

#include <simd/simd.h>

typedef struct {
    vector_float4 position;
    vertor_float2 textureCoordinate;
} Vertex;

typedef struct {
    matrix_float3x3 matrix;
    vector_float3 offset;
}ConvertMartix;



#endif /* HobenShaderType_h */
