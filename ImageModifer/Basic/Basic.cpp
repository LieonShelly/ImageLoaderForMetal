//
//  Basic.cpp
//  ImageModifer
//
//  Created by Renjun Li on 2022/4/19.
//

#include "Basic.hpp"

int f_thread(unsigned char *srcData, int width, int height, int T) {
    int ret = 0;
    int i, j, gray, offset;
    offset = 1;
    unsigned char *pSrc = srcData;
    for (j = 0; j < height; j++) {
        for (i = 0; i < width; i++) {
            gray = (pSrc[0] + pSrc[1] + pSrc[2]) / 3;
            gray = gray < T ? 0 : 255;
            pSrc[0] = gray;
            pSrc[1] = gray;
            pSrc[2] = gray;
            
            printf("%ld - %ld - %ld - ", pSrc[0], pSrc[1], pSrc[2]);
            pSrc += 4; // 移动到下一个像素点
        }
        printf("\n");
        pSrc += offset; // 移动到下一行
    }
    return ret;
}
