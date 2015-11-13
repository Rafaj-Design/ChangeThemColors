//
//  NSImage+RIColor.m
//  ChangeThemColors
//
//  Created by Ondrej Rafaj on 12/11/2015.
//  Copyright © 2015 Ridiculous Innovations. All rights reserved.
//

#import "NSImage+RIColor.h"


@implementation NSImage (RIColor)


+ (NSImage *)replaceColor:(NSColor *)color withColor:(NSColor *)newColor inImage:(NSImage *)image useOldAlpha:(BOOL)useAlpha withTolerance:(CGFloat)tolerance {
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)[image TIFFRepresentation], NULL);
    CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
    
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    NSUInteger bitmapByteCount = bytesPerRow * height;
    
    unsigned char *rawData = (unsigned char *) calloc(bitmapByteCount, sizeof(unsigned char));
    
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    CGColorRef cgColor = [color CGColor];
    const CGFloat *components = CGColorGetComponents(cgColor);
    float r = components[0];
    float g = components[1];
    float b = components[2];
    
    r = (r * 255.0);
    g = (g * 255.0);
    b = (b * 255.0);
    
    const float redRange[2] = {
        MAX(r - (tolerance / 2.0), 0.0),
        MIN(r + (tolerance / 2.0), 255.0)
    };
    
    const float greenRange[2] = {
        MAX(g - (tolerance / 2.0), 0.0),
        MIN(g + (tolerance / 2.0), 255.0)
    };
    
    const float blueRange[2] = {
        MAX(b - (tolerance / 2.0), 0.0),
        MIN(b + (tolerance / 2.0), 255.0)
    };
    
    int byteIndex = 0;
    
    CGColorRef cgColorNew = [newColor CGColor];
    const CGFloat *componentsNew = CGColorGetComponents(cgColorNew);
    float nr = componentsNew[0];
    float ng = componentsNew[1];
    float nb = componentsNew[2];
    float na = componentsNew[3];
    
    nr = (nr * 255.0);
    ng = (ng * 255.0);
    nb = (nb * 255.0);
    na = (na * 255.0);
    
    while (byteIndex < bitmapByteCount) {
        unsigned char red   = rawData[byteIndex];
        unsigned char green = rawData[byteIndex + 1];
        unsigned char blue  = rawData[byteIndex + 2];
        unsigned char alpha  = rawData[byteIndex + 3];
        
        if (((red >= redRange[0]) && (red <= redRange[1])) && ((green >= greenRange[0]) && (green <= greenRange[1])) && ((blue >= blueRange[0]) && (blue <= blueRange[1]))) {
            rawData[byteIndex] = nr;
            rawData[byteIndex + 1] = ng;
            rawData[byteIndex + 2] = nb;
            
            if (useAlpha) {
                rawData[byteIndex + 3] = alpha;
            }
            else {
                rawData[byteIndex + 3] = na;
            }
        }
        
        byteIndex += 4;
    }
    
    NSImage *result = [[NSImage alloc] initWithCGImage:CGBitmapContextCreateImage(context) size:image.size];
    
    CGContextRelease(context);
    free(rawData);
    
    return result;
}


@end
