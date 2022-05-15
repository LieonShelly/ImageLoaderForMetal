//
//  HobenShaderType.h
//  ImageModifer
//
//  Created by Renjun Li on 2022/5/4.
//
/*
#ifndef HobenShaderType_h
#define HobenShaderType_h

#include <simd/simd.h>

typedef struct {
    vector_float4 position;
    vector_float2 textureCoordinate;
} Vertex;

typedef struct {
    matrix_float3x3 matrix;
    vector_float3 offset;
}ConvertMartix;


// BT.601
static const ConvertMartix HobenYUVColorConversion601 = {
    .matrix = {
        .columns[0] = { 1.164,  1.164, 1.164, },
        .columns[1] = { 0.000, -0.392, 2.017, },
        .columns[2] = { 1.596, -0.813, 0.000, },
    },
    .offset = { -(16.0/255.0), -0.5, -0.5 },
};

// BT.601 Full Range
static const ConvertMartix HobenYUVColorConversion601FullRange = {
    .matrix = {
        .columns[0] = { 1.000,  1.000, 1.000, },
        .columns[1] = { 0.000, -0.343, 1.765, },
        .columns[2] = { 1.400, -0.711, 0.000, },
    },
    .offset = { 0.0, -0.5, -0.5 },
};

// BT.709
static const ConvertMartix HobenYUVColorConversion709 = {
    .matrix = {
        .columns[0] = { 1.164,  1.164, 1.164, },
        .columns[1] = { 0.000, -0.213, 2.112, },
        .columns[2] = { 1.793, -0.533, 0.000, },
    },
    .offset = { -(16.0/255.0), -0.5, -0.5 },
};


#endif /* HobenShaderType_h */

