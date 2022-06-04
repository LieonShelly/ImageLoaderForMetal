//
//  LYShaderTypes.h
//  LearnMetal
//
//  Created by loyinglin on 2018/6/21.

//

#ifndef LYShaderTypes_h
#define LYShaderTypes_h

#include <simd/simd.h>

typedef struct
{
    vector_float4 position;
    vector_float2 textureCoordinate;
} LYVertex;


typedef struct {
    matrix_float3x3 matrix;
    vector_float3 offset;
} LYConvertMatrix;


typedef enum LYVertexInputIndex
{
    LYVertexInputIndexVertices     = 0,
} LYVertexInputIndex;


typedef enum LYFragmentTextureIndex
{
    LYFragmentTextureIndexTextureSource     = 0,
    LYFragmentTextureIndexTextureDest       = 1,
} LYFragmentTextureIndex;




#endif /* LYShaderTypes_h */
