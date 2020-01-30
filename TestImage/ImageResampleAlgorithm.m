//
//  ImageResampleAlgorithm.m
//  TestImage
//
//  Created by Zhang on 2020/1/30.
//  Copyright © 2020 Zhang. All rights reserved.
//

#import "ImageResampleAlgorithm.h"
#import <UIKit/UIKit.h>

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )


@implementation ImageResampleAlgorithm

+ (void)test {
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ming_little" ofType:@"png"];
    UIImage *originalUIImage = [[UIImage alloc]initWithContentsOfFile:filePath];
    CGFloat ratio = originalUIImage.size.width / originalUIImage.size.height;
    CGFloat showWidth = 70.0;
    CGFloat showHeight = showWidth / ratio;
    
    CGImageRef cgOriginalImage = originalUIImage.CGImage;
    NSUInteger bytesPerPixel = CGImageGetBitsPerPixel(cgOriginalImage) / 8;
    NSUInteger bytesPerRow = CGImageGetBytesPerRow(cgOriginalImage);
    NSUInteger bitsPerComponent = CGImageGetBitsPerComponent(cgOriginalImage);
    int width = (int)CGImageGetWidth(cgOriginalImage);
    int height = (int)CGImageGetHeight(cgOriginalImage);
    
    UInt32* pixelData = (UInt32 *)calloc(width * height, sizeof(UInt32));
    if (!pixelData) {
        NSException *exception = [NSException exceptionWithName:@"AlphaPixelsException"
               reason:@"Unable to allocate memory for pixel data"
                userInfo:nil];
        @throw exception;
    }

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixelData,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

    if (!context) {
        NSException *exception = [NSException exceptionWithName:@"AlphaPixelsException"
               reason:@"Unable to create bitmap context"
                userInfo:nil];
        @throw exception;
    }

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgOriginalImage);
    
    CGContextRelease(context);

    // Resample image: nearest neighbor interpolation 最近邻插值算法
    UInt32* rgba1 = scaleImageWithNearesNeighborInterpolation(pixelData, width, height, showWidth, showHeight);
    
    // Resample image: Bilinear Interpolation 双线性插值算法
    UInt32* rgba2 = scaleImageWithLinearInterpolation(pixelData, width, height, showWidth, showHeight);
    
    UInt32* rgba3 = scaleImageWithBicubicInterpolation(pixelData, width, height, showWidth, showHeight);

    [self savePixelData:rgba1
                  width:showWidth
                 height:showHeight
       bitsPerComponent:bitsPerComponent
            bytesPerRow:bytesPerPixel * showWidth
             colorSpace:colorSpace
               saveName:@"nearest.png"];
    
    [self savePixelData:rgba2
                  width:showWidth
                 height:showHeight
       bitsPerComponent:bitsPerComponent
            bytesPerRow:bytesPerPixel * showWidth
             colorSpace:colorSpace
               saveName:@"bilinear.png"];
    
    [self savePixelData:rgba3
                  width:showWidth
                 height:showHeight
       bitsPerComponent:bitsPerComponent
            bytesPerRow:bytesPerPixel * showWidth
             colorSpace:colorSpace
               saveName:@"bicubic.png"];
    
    CFRelease(colorSpace);
    free(rgba1);
    free(rgba2);
}

+ (void)savePixelData:(UInt32*)rgba
                width:(CGFloat)width
               height:(CGFloat)height
     bitsPerComponent:(CGFloat)bitsPerComponent
          bytesPerRow:(CGFloat)bytesPerRow
           colorSpace:(CGColorSpaceRef)colorSpace
             saveName:(NSString*)imageName {
    
    CGContextRef bitmapContext = CGBitmapContextCreate(
                                                       rgba,
                                                       width,
                                                       height,
                                                       bitsPerComponent,
                                                       bytesPerRow,
                                                       colorSpace,
                                                       kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
    UIImage *newUIImage = [UIImage imageWithCGImage:cgImage];

    [self saveImage:newUIImage withName:imageName];
    
    CGImageRelease(cgImage);
}

+ (void)saveImage:(UIImage *)image withName:(NSString *)imageName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:imageName];

    NSLog(@"save to file %@", filePath);
    [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
}

// Resample image: nearest neighbor interpolation 最近邻插值算法
static UInt32* scaleImageWithNearesNeighborInterpolation(UInt32* pixelData, int sourceWidth, int sourceHeight, int desWidth, int desHeight) {
    
    float rowRatio = ((float)sourceHeight) / ((float)desHeight);
    float colRatio = ((float)sourceWidth) / ((float)desWidth);
    UInt32* rgba = (UInt32 *)calloc(desWidth * desHeight, sizeof(UInt32));
    int offset=0;
    for(int i = 0; i < desHeight; ++i) {
        // round是四舍五入,0.5 = 1
        int srcRow = floor(((float)i)*rowRatio);
        if(srcRow >= sourceHeight) {
            srcRow = sourceHeight - 1;
        }
        
        for (int j = 0; j < desWidth; j++) {
            
            int srcCol = floor(((float)j)*colRatio);
            if(srcCol >= sourceWidth) {
                srcCol = sourceWidth - 1;
            }
            
            rgba[offset]   = pixelData[(srcRow * sourceWidth + srcCol)];
            offset++;
        }
    }
    
    return rgba;
}

// Resample image: bilinear interpolation 双线性插值算法
static UInt32* scaleImageWithLinearInterpolation(UInt32* pixelData, int sourceWidth, int sourceHeight, int desWidth, int desHeight) {
    
    float rowRatio = ((float)sourceHeight) / ((float)desHeight);
    float colRatio = ((float)sourceWidth) / ((float)desWidth);
    UInt32* rgba = (UInt32 *)calloc(desWidth * desHeight, sizeof(UInt32));
    int offset=0;
    for(int row = 0; row < desHeight; row++) {
        double srcRow = ((float)row) * rowRatio;
        double j = floor(srcRow);
        double u = srcRow - j;
        
        for (int col = 0; col < desWidth; col++) {
            
            double srcCol = ((float)col) * colRatio;
            double k = floor(srcCol);
            double t = srcCol - k;
            double coffiecent1 = (1.0 - t) * (1.0 - u);
            double coffiecent2 = (1.0 - t) * u;
            double coffiecent3 = t * u;
            double coffiecent4 = (t) * (1.0 - u);
            
            // 四个角的颜色值
            UInt32 inputColor00 = pixelData[(getClip((int)j, sourceHeight - 1 , 0) * sourceWidth + getClip((int)k, sourceWidth - 1, 0))];
            UInt32 inputColor10 = pixelData[(getClip((int)(j+1), sourceHeight - 1 , 0) * sourceWidth + getClip((int)k, sourceWidth - 1, 0))];
            UInt32 inputColor11 = pixelData[(getClip((int)(j+1), sourceHeight - 1 , 0) * sourceWidth + getClip((int)(k+1), sourceWidth - 1, 0))];
            UInt32 inputColor01 = pixelData[(getClip((int)j, sourceHeight - 1 , 0) * sourceWidth + getClip((int)(k+1), sourceWidth - 1, 0))];
            
            // 新的透明度
            UInt32 newA = (UInt32)(
                                coffiecent1 * A(inputColor00) +
                                coffiecent2 * A(inputColor10) +
                                coffiecent3 * A(inputColor11) +
                                coffiecent4 * A(inputColor01)
                                );
            
            // 新的R分量的值
            double r00 = R(inputColor00) * (255.0 / A(inputColor00));
            double r10 = R(inputColor10) * (255.0 / A(inputColor10));
            double r11 = R(inputColor11) * (255.0 / A(inputColor11));
            double r01 = R(inputColor01) * (255.0 / A(inputColor01));
            UInt32 newR = (UInt32)((
                                    coffiecent1 * r00 +
                                    coffiecent2 * r10 +
                                    coffiecent3 * r11 +
                                    coffiecent4 * r01
                                    ) * (newA / 255.0));
            
            // 新的G分量的值
            double g00 = G(inputColor00) * (255.0 / A(inputColor00));
            double g10 = G(inputColor10) * (255.0 / A(inputColor10));
            double g11 = G(inputColor11) * (255.0 / A(inputColor11));
            double g01 = G(inputColor01) * (255.0 / A(inputColor01));
            UInt32 newG = (UInt32)((
                                    coffiecent1 * g00 +
                                    coffiecent2 * g10 +
                                    coffiecent3 * g11 +
                                    coffiecent4 * g01
                                    ) * (newA / 255.0));
            
            // 新的B分量的值
            double b00 = B(inputColor00) * (255.0 / A(inputColor00));
            double b10 = B(inputColor10) * (255.0 / A(inputColor10));
            double b11 = B(inputColor11) * (255.0 / A(inputColor11));
            double b01 = B(inputColor01) * (255.0 / A(inputColor01));
            UInt32 newB = (UInt32)((
                                    coffiecent1 * b00 +
                                    coffiecent2 * b10 +
                                    coffiecent3 * b11 +
                                    coffiecent4 * b01
                                    ) * (newA / 255.0));
            
            rgba[offset] = RGBAMake(newR, newG, newB, newA);
            offset++;
        }
    }
    
    return rgba;
}


static double a00, a01, a02, a03;
static double a10, a11, a12, a13;
static double a20, a21, a22, a23;
static double a30, a31, a32, a33;
static UInt32* scaleImageWithBicubicInterpolation(UInt32* pixelData, int sourceWidth, int sourceHeight, int desWidth, int desHeight) {
    
    UInt32 tempPixels[4][4];
    float rowRatio = ((float)sourceHeight) / ((float)desHeight);
    float colRatio = ((float)sourceWidth) / ((float)desWidth);
    UInt32* rgba = (UInt32 *)calloc(desWidth * desHeight, sizeof(UInt32));
    int offset=0;
    for(int row = 0; row < desHeight; row++) {
        double srcRow = ((float)row) * rowRatio;
        double j = floor(srcRow);
        double u = srcRow - j;
        
        for (int col = 0; col < desWidth; col++) {
            
            double srcCol = ((float)col) * colRatio;
            double k = floor(srcCol);
            double t = srcCol - k;
            UInt32 newR = 255;
            UInt32 newG = 255;
            UInt32 newB = 255;
            UInt32 newA = 255;
            
            for(int i=0; i<4; i++) {
                tempPixels[0][0] = getRGBValue(pixelData, j-1, k-1, i, sourceWidth, sourceHeight);
                tempPixels[0][1] = getRGBValue(pixelData, j-1, k, i, sourceWidth, sourceHeight);
                tempPixels[0][2] = getRGBValue(pixelData, j-1, k+1, i, sourceWidth, sourceHeight);
                tempPixels[0][3] = getRGBValue(pixelData, j-1, k+2,i, sourceWidth, sourceHeight);
                
                tempPixels[1][0] = getRGBValue(pixelData, j, k-1, i, sourceWidth, sourceHeight);
                tempPixels[1][1] = getRGBValue(pixelData, j, k, i, sourceWidth, sourceHeight);
                tempPixels[1][2] = getRGBValue(pixelData, j, k+1, i, sourceWidth, sourceHeight);
                tempPixels[1][3] = getRGBValue(pixelData, j, k+2, i, sourceWidth, sourceHeight);
                
                tempPixels[2][0] = getRGBValue(pixelData, j+1, k-1, i, sourceWidth, sourceHeight);
                tempPixels[2][1] = getRGBValue(pixelData, j+1, k, i, sourceWidth, sourceHeight);
                tempPixels[2][2] = getRGBValue(pixelData, j+1, k+1, i, sourceWidth, sourceHeight);
                tempPixels[2][3] = getRGBValue(pixelData, j+1, k+2, i, sourceWidth, sourceHeight);
                
                tempPixels[3][0] = getRGBValue(pixelData, j+2, k-1, i, sourceWidth, sourceHeight);
                tempPixels[3][1] = getRGBValue(pixelData, j+2, k, i, sourceWidth, sourceHeight);
                tempPixels[3][2] = getRGBValue(pixelData, j+2, k+1, i, sourceWidth, sourceHeight);
                tempPixels[3][3] = getRGBValue(pixelData, j+2, k+2, i, sourceWidth, sourceHeight);
                
                // update coefficients
                updateCoefficients(tempPixels);
                if (i == 0) {
                    newR = getPixelValue(getValue(u, t));
                } else if (i == 1) {
                    newG = getPixelValue(getValue(u, t));
                } else if (i == 2) {
                    newB = getPixelValue(getValue(u, t));
                } else {
                    newA = getPixelValue(getValue(u, t));
                }
            }

            rgba[offset] = RGBAMake(newR, newG, newB, newA);
            offset++;
        }
    }
    
    return rgba;
}

static UInt32 getRGBValue(UInt32* pixelData, double row, double col, int index, int width, int height) {
    UInt32 inputColor = pixelData[(getClip((int)row, height - 1 , 0) * width + getClip((int)col, width - 1, 0))];
    
    if (index == 0) {
        return R(inputColor);
    } else if (index == 1) {
        return G(inputColor);
    } else if (index == 2) {
        return B(inputColor);
    } else {
        return A(inputColor);
    }
}

static double getValue(double x, double y) {
    double x2 = x * x;
    double x3 = x2 * x;
    double y2 = y * y;
    double y3 = y2 * y;

    return (a00 + a01 * y + a02 * y2 + a03 * y3) +
           (a10 + a11 * y + a12 * y2 + a13 * y3) * x +
           (a20 + a21 * y + a22 * y2 + a23 * y3) * x2 +
           (a30 + a31 * y + a32 * y2 + a33 * y3) * x3;
}

static UInt32 getPixelValue(double pixelValue) {
    return pixelValue < 0 ? 0 : pixelValue > 255.0 ? 255 : (UInt32)pixelValue;
}

static void updateCoefficients(UInt32 p[4][4]) {
        a00 = p[1][1];
        a01 = -.5*p[1][0] + .5*p[1][2];
        a02 = p[1][0] - 2.5*p[1][1] + 2*p[1][2] - .5*p[1][3];
        a03 = -.5*p[1][0] + 1.5*p[1][1] - 1.5*p[1][2] + .5*p[1][3];
        a10 = -.5*p[0][1] + .5*p[2][1];
        a11 = .25*p[0][0] - .25*p[0][2] - .25*p[2][0] + .25*p[2][2];
        a12 = -.5*p[0][0] + 1.25*p[0][1] - p[0][2] + .25*p[0][3] + .5*p[2][0] - 1.25*p[2][1] + p[2][2] - .25*p[2][3];
        a13 = .25*p[0][0] - .75*p[0][1] + .75*p[0][2] - .25*p[0][3] - .25*p[2][0] + .75*p[2][1] - .75*p[2][2] + .25*p[2][3];
        a20 = p[0][1] - 2.5*p[1][1] + 2*p[2][1] - .5*p[3][1];
        a21 = -.5*p[0][0] + .5*p[0][2] + 1.25*p[1][0] - 1.25*p[1][2] - p[2][0] + p[2][2] + .25*p[3][0] - .25*p[3][2];
        a22 = p[0][0] - 2.5*p[0][1] + 2*p[0][2] - .5*p[0][3] - 2.5*p[1][0] + 6.25*p[1][1] - 5*p[1][2] + 1.25*p[1][3] + 2*p[2][0] - 5*p[2][1] + 4*p[2][2] - p[2][3] - .5*p[3][0] + 1.25*p[3][1] - p[3][2] + .25*p[3][3];
        a23 = -.5*p[0][0] + 1.5*p[0][1] - 1.5*p[0][2] + .5*p[0][3] + 1.25*p[1][0] - 3.75*p[1][1] + 3.75*p[1][2] - 1.25*p[1][3] - p[2][0] + 3*p[2][1] - 3*p[2][2] + p[2][3] + .25*p[3][0] - .75*p[3][1] + .75*p[3][2] - .25*p[3][3];
        a30 = -.5*p[0][1] + 1.5*p[1][1] - 1.5*p[2][1] + .5*p[3][1];
        a31 = .25*p[0][0] - .25*p[0][2] - .75*p[1][0] + .75*p[1][2] + .75*p[2][0] - .75*p[2][2] - .25*p[3][0] + .25*p[3][2];
        a32 = -.5*p[0][0] + 1.25*p[0][1] - p[0][2] + .25*p[0][3] + 1.5*p[1][0] - 3.75*p[1][1] + 3*p[1][2] - .75*p[1][3] - 1.5*p[2][0] + 3.75*p[2][1] - 3*p[2][2] + .75*p[2][3] + .5*p[3][0] - 1.25*p[3][1] + p[3][2] - .25*p[3][3];
        a33 = .25*p[0][0] - .75*p[0][1] + .75*p[0][2] - .25*p[0][3] - .75*p[1][0] + 2.25*p[1][1] - 2.25*p[1][2] + .75*p[1][3] + .75*p[2][0] - 2.25*p[2][1] + 2.25*p[2][2] - .75*p[2][3] - .25*p[3][0] + .75*p[3][1] - .75*p[3][2] + .25*p[3][3];
}

static int getClip(int x, int max, int min) {
    return x > max ? max : x < min? min : x;
}

@end
