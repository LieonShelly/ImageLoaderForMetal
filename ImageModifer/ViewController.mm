//
//  ViewController.m
//  ImageModifer
//
//  Created by Renjun Li on 2022/4/13.
//

/**
 
 - 获取到图像数据
 - 根据图像数据渲染出图像到屏幕
 */

#import "ViewController.h"
#include<stdlib.h>
#include<math.h>
#include<string.h>
#include<stdio.h>
#include "Basic.hpp"

@interface ViewController()
{
    uint8_t* bitmapData;
}

@property(nonatomic, strong) NSImageView *imageView;
@property(nonatomic, strong) NSData *imageData;
@property(nonatomic, strong) NSImage *image;

@end

@implementation ViewController

- (NSImageView *)imageView {
    if (!_imageView) {
        _imageView = [NSImageView new];
    }
    return _imageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.wantsLayer = true;
    self.view.layer.backgroundColor = NSColor.blueColor.CGColor;
    self.imageView.frame = self.view.bounds;
    [self.view addSubview:self.imageView];
    [self getImageData];
    /**
     pixelRGB((unsigned char *)bitmapData,
              self.image.size.width,
              self.image.size.height,
              (int)imgLocation.x,
              (int)self.image.size.height - (int)imgLocation.y,
              rgb);
     */
    
    f_thread((unsigned char *)bitmapData, self.image.size.width, self.image.size.height, 64);
}


void pixelRGB(const uint8_t *srcData, int width, int height, int x, int y, int rgb[3]) {
    // 获取当前坐标点的位置
    x = x < 0 ? 0 : (x > width - 1 ? width - 1 : x);
    y = y < 0 ? 0 : (y > height - 1 ? height - 1 : y);
    int pos = x * 4 + (y - 1) * width * 4;
    if (y - 1 <= 0) {
        pos = x * 4;
    }
    rgb[0] = srcData[pos + 2];
    rgb[1] = srcData[pos + 1];
    rgb[2] = srcData[pos + 0];
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint location = [event locationInWindow];
    NSPoint imgLocation = [self.imageView convertPoint:location fromView:self.view];
    int rgb[3] = {0, 0, 0};
    pixelRGB((unsigned char *)bitmapData,
             self.image.size.width,
             self.image.size.height,
             (int)imgLocation.x,
             (int)self.image.size.height - (int)imgLocation.y,
             rgb);
    NSLog(@"r: %d, g: %d, b:%d", rgb[0], rgb[1], rgb[2]);
}

- (void)mouseUp:(NSEvent *)event {
    
}

- (void)getImageData {
    NSString * imgpath = [[NSBundle mainBundle]pathForImageResource:@"red.jpeg"];
    self.image = [[NSImage alloc]initWithContentsOfURL:[NSURL fileURLWithPath:imgpath]];
    self.imageView.frame = CGRectMake(0, 0, self.image.size.width, self.image.size.height);
    self.imageView.image = self.image;
    int width = self.image.size.width;
    int height = self.image.size.height;
    self.imageData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:imgpath]];
    int pixelCount = self.image.size.width * self.image.size.height;
    
    NSData *imageData = [NSData dataWithContentsOfFile:imgpath];
    CFDataRef dataRef = (__bridge CFDataRef)imageData;
    CGImageSourceRef source = CGImageSourceCreateWithData(dataRef, nil);
    CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil);
    
    bitmapData = (uint8_t *)calloc(pixelCount * 4, sizeof(uint8_t));
    int bytesPerRow = 4 * width;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(bitmapData, width, height, 8, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    if (!context) {
        return ;
    }
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);

    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    
}


@end
