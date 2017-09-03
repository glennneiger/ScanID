//
//  OCRManager.m
//  OCRDemo
//
//  Created by ltp on 5/26/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "OCRManager.h"

#define NOEDGE 0
#define POSSIBLE_EDGE 128
#define EDGE 255

static const int kRed = 1;
static const int kGreen = 2;
static const int kBlue = 3;

@implementation OCRManager {
    NSInteger _width;
    NSInteger _height;
    uint8_t *_imageData;
    int *_gradx;
    int *_grady;
    int *_mag;
}

- (instancetype)init{
    if (self = [super init]) {
        
    }
    return self;
}

- (void)dealloc{
//    [super dealloc];
    if (_imageData) {
        free(_imageData);
        _imageData = NULL;
    }
    if (_mag) {
        free(_mag);
        _mag = NULL;
    }
    if (_gradx) {
        free(_gradx);
        _gradx = NULL;
    }
    if (_grady) {
        free(_grady);
        _grady = NULL;
    }
}

-(NSString *)scanPic{
    NSString *res = @"";
    
//    uint8_t *uc[88][25] = {0};
//    uint8_t *grayImage[135][700] = {0};
//    uint8_t *blackImage[135][88] = {0};
    return res;
}

//edge detection
- (UIImage *)getEdge:(UIImage *)image{
    UIImage *retImage = nil;
    
    CGSize size = image.size;
    NSInteger width = size.width / 4;
    NSInteger height = size.height / 4;
    _width = width;
    _height = height;
    if (_imageData) {
        free(_imageData);
        _imageData = NULL;
    }
    _imageData = malloc(sizeof(uint8_t) * width * height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(_imageData, width, height, 8, width, colorSpace, kCGImageAlphaNone);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, NO);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    [self gaussianBlur];
    
    [self cannyEdgeExtractWithTLow:0.3 THigh:0.7];
    
    retImage = [self imageFromBitMap];
    if (_imageData) {
        free(_imageData);
        _imageData = NULL;
    }
    return retImage;
}

-(void)cannyEdgeExtractWithTLow:(float)lowThreshhold THigh:(float)highThreshhold{
    //sobel operator
    int gx[3][3] = {
        { -1,  0,  1},
        { -2,  0,  2},
        { -1,  0,  1}
    };
    int gy[3][3] = {
        {  1,  2,  1},
        {  0,  0,  0},
        { -1, -2,  1}
    };
    NSInteger retHeight = _height - 3;
    NSInteger retWidth = _width - 3;
    int *diffx = malloc(sizeof(int) * retWidth * retHeight);    //horizonal derivative
    int *diffy = malloc(sizeof(int) * retWidth * retHeight);    //vertical derivative
    int *mag = malloc(sizeof(int) * retWidth * retHeight);      //gradient magnitude
    memset(diffx, 0, sizeof(int) * retWidth * retHeight);
    memset(diffy, 0, sizeof(int) * retWidth * retHeight);
    memset(mag, 0, sizeof(int) * retWidth * retHeight);
    //compute magnitude
    for (int y = 0; y < retHeight; y++) {
        for (int x = 0; x < retWidth; x++) {
            int derX = 0;
            int derY = 0;
            for (int dy = 0; dy < 3; dy++) {
                for (int dx = 0; dx < 3; dx++) {
                    int pixel = _imageData[(y+dy) * _width + (x + dx)];
                    derX += pixel * gx[dy][dx];
                    derY += pixel * gy[dy][dx];
                }
            }
            mag[y * retWidth + x] = abs(derX) + abs(derY);
            diffx[y * retWidth + x] = derX;
            diffy[y * retWidth + x] = derY;
        }
    }
    _mag = mag;
    _gradx = diffx;
    _grady = diffy;
    _width = retWidth;
    _height = retHeight;
    //non max suppression
    uint8_t *filteredImage = malloc(sizeof(uint8_t) * retWidth * retHeight);
    memset(filteredImage, 0, sizeof(uint8_t) * retWidth * retHeight);
    [self suppressNonMaxium:filteredImage];

    free(_gradx);
    _gradx = NULL;
    free(_grady);
    _grady = NULL;
    
    uint8_t *edge = malloc(sizeof(uint8_t)*retHeight*retWidth);
    memset(edge, 0, sizeof(uint8_t) * retWidth * retHeight);
    [self applyHystesis:filteredImage highThreshold:highThreshhold lowThreshold:lowThreshhold edge:edge];
    free(filteredImage);
    filteredImage = NULL;
    
    _imageData = edge ;
}

- (void)applyHystesis:(uint8_t *)possibleEdges highThreshold:(float)highT lowThreshold:(float)lowT edge:(uint8_t *)edge{
    int edgesCount = 0, numHighEdges = 0, maxMag = 0, lowThreshold = 0, highThreshold = 0;
    int hist[32768] = {0};  //256*16*8
    NSInteger pos;
    /****************************************************************************
     * Initialize the edge map to possible edges everywhere the non-maximal
     * suppression suggested there could be an edge except for the border. At
     * the border we say there can not be an edge because it makes the
     * follow_edges algorithm more efficient to not worry about tracking an
     * edge off the side of the image.
     ****************************************************************************/
    for(int r=0,pos=0;r<_height;r++){
        for(int c=0;c<_width;c++,pos++){
            if(possibleEdges[pos] == POSSIBLE_EDGE) edge[pos] = POSSIBLE_EDGE;
            else edge[pos] = NOEDGE;
        }
    }
    
    for(int r=0,pos=0;r<_height;r++,pos+=_width){
        edge[pos] = NOEDGE;
        edge[pos+_width-1] = NOEDGE;
    }
    pos = (_height-1) * _width;
    for(int c=0;c<_height;c++,pos++){
        edge[c] = NOEDGE;
        edge[pos] = NOEDGE;
    }
    /****************************************************************************
     * Compute the histogram of the magnitude image. Then use the histogram to
     * compute hysteresis thresholds.
     ****************************************************************************/
    for(int r=0;r<32768;r++) hist[r] = 0;
    for(int r=0,pos=0;r<_height;r++){
        for(int c=0;c<_width;c++,pos++){
            if(edge[pos] == POSSIBLE_EDGE) hist[_mag[pos]]++;
        }
    }
    
    /****************************************************************************
     * Compute the number of pixels that passed the nonmaximal suppression.
     ****************************************************************************/
    for(int r=1,edgesCount=0;r<32768;r++){
        if(hist[r] != 0) maxMag = r;
        edgesCount += hist[r];
    }
    //edges that gratidude larger than high threshold
    numHighEdges = (int)(edgesCount * highT + 0.5);
    
    /****************************************************************************
     * Compute the high threshold value as the (100 * thigh) percentage point
     * in the magnitude of the gradient histogram of all the pixels that passes
     * non-maximal suppression. Then calculate the low threshold as a fraction
     * of the computed high threshold value. John Canny said in his paper
     * "A Computational Approach to Edge Detection" that "The ratio of the
     * high to low threshold in the implementation is in the range two or three
     * to one." That means that in terms of this implementation, we should
     * choose tlow ~= 0.5 or 0.33333.
     ****************************************************************************/
    int r = 1;
    edgesCount = hist[1];
    while((r<(maxMag-1)) && (edgesCount < numHighEdges)){
        r++;
        edgesCount += hist[r];
    }
    highThreshold = r;
    lowThreshold = (int)(numHighEdges * lowT + 0.5);
    
    /****************************************************************************
     * This loop looks for pixels above the highthreshold to locate edges and
     * then calls follow_edges to continue the edge.
     ****************************************************************************/
    for(int r=0,pos=0;r<_height;r++){
        for(int c=0;c<_width;c++,pos++){
            if((edge[pos] == POSSIBLE_EDGE) && (_mag[pos] >= highThreshold)){
                edge[pos] = EDGE;
                [self followEdges:(edge+pos) mag:(_mag+pos) lowThreshold:lowThreshold width:(int)_width];
            }
        }
    }
    
    /****************************************************************************
     * Set all the remaining possible edges to non-edges.
     ****************************************************************************/
    for(int r=0,pos=0;r<_height;r++){
        for(int c=0;c<_width;c++,pos++) if(edge[pos] != EDGE) edge[pos] = NOEDGE;
    }

}

- (void)followEdges:(uint8_t *)edgeMapPtr mag:(int *)edgeMagPtr lowThreshold:(short)lowval width:(int)cols{
    int *tempMagPtr;
    uint8_t *tempMapPtr;
    int i;
    
    /****************************************************************************
     * The x pixel is which should get checked:
     *  x x x
     *  x o x
     *  x x x
     ****************************************************************************/
    int x[8] = {1,1,0,-1,-1,-1,0,1},
    y[8] = {0,1,1,1,0,-1,-1,-1};
    
    for(i=0;i<8;i++){
        tempMapPtr = edgeMapPtr - y[i]*cols + x[i];
        tempMagPtr = edgeMagPtr - y[i]*cols + x[i];
        
        if((*tempMapPtr == POSSIBLE_EDGE) && (*tempMagPtr > lowval)){
            *tempMapPtr = (unsigned char) EDGE;
            [self followEdges:tempMapPtr mag:tempMagPtr lowThreshold:lowval width:cols];
        }
    }
}


- (void)suppressNonMaxium:(uint8_t*)result{
    int rowCount, colCount, count;
    int *magRowPtr, *magPtr;
    int *gxRowPtr, *gxPtr;
    int *gyRowPtr, *gyPtr;
    int m00, gx = 0, gy = 0, z1 = 0, z2 = 0;
    float mag1, mag2, xperp = 0.0f, yperp = 0.0f; //magnitude of beside points, x perpendicular, y perpendicular
    uint8_t *resultRowPtr, *resultPtr;

    /****************************************************************************
     * Zero the edges of the result image.
     ****************************************************************************/
    for (count = 0, resultPtr = result, resultRowPtr = result + _width * (_height - 1) + 1;
         count < _width;
         count++, resultPtr++, resultRowPtr++) {
         *resultRowPtr = *resultPtr = (uint8_t)0;
    }
    for (count = 0, resultPtr = result, resultRowPtr = result + _width - 1;
         count < _height;
         count++, resultRowPtr++, resultPtr++) {
         *resultRowPtr = *resultPtr = (uint8_t)0;
    }
    
    /****************************************************************************
     * Suppress non-maximum points.
     ****************************************************************************/
    for(rowCount = 1, magRowPtr = _mag + _width + 1, gxRowPtr = _gradx + _width + 1,
        gyRowPtr = _grady + _width + 1, resultRowPtr = result + _width + 1;
        rowCount < _height - 2;
        rowCount++, magRowPtr += _width, gyRowPtr += _width, gxRowPtr += _width,
        resultRowPtr += _width){
        for(colCount = 1, magPtr = magRowPtr, gxPtr = gxRowPtr, gyPtr = gyRowPtr, resultPtr = resultRowPtr;
            colCount < _width-2;
            colCount++,magPtr++,gxPtr++,gyPtr++,resultPtr++){
            m00 = *magPtr;
            if(m00 == 0){
                *resultPtr = (unsigned char) NOEDGE;
            }
            else{
                xperp = -(gx = *gxPtr)/((float)m00);
                yperp = (gy = *gyPtr)/((float)m00);
            }
            //linear interpolation
            if(gx >= 0){
                if(gy >= 0){
                    if (gx >= gy)
                    {
                        /* 111 */
                        /* Left point */
                        z1 = *(magPtr - 1);
                        z2 = *(magPtr - _width - 1);
                        
                        mag1 = (m00 - z1)*xperp + (z2 - z1)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr + 1);
                        z2 = *(magPtr + _width + 1);
                        
                        mag2 = (m00 - z1)*xperp + (z2 - z1)*yperp;
                    }
                    else
                    {
                        /* 110 */
                        /* Left point */
                        z1 = *(magPtr - _width);
                        z2 = *(magPtr - _width - 1);
                        
                        mag1 = (z1 - z2)*xperp + (z1 - m00)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr + _width);
                        z2 = *(magPtr + _width + 1);
                        
                        mag2 = (z1 - z2)*xperp + (z1 - m00)*yperp;
                    }
                }
                else
                {
                    if (gx >= -gy)
                    {
                        /* 101 */
                        /* Left point */
                        z1 = *(magPtr - 1);
                        z2 = *(magPtr + _width - 1);
                        
                        mag1 = (m00 - z1)*xperp + (z1 - z2)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr + 1);
                        z2 = *(magPtr - _width + 1);
                        
                        mag2 = (m00 - z1)*xperp + (z1 - z2)*yperp;
                    }
                    else
                    {
                        /* 100 */
                        /* Left point */
                        z1 = *(magPtr + _width);
                        z2 = *(magPtr + _width - 1);
                        
                        mag1 = (z1 - z2)*xperp + (m00 - z1)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr - _width);
                        z2 = *(magPtr - _width + 1);
                        
                        mag2 = (z1 - z2)*xperp  + (m00 - z1)*yperp;
                    }
                }
            }
            else
            {
                if ((gy = *gyPtr) >= 0)
                {
                    if (-gx >= gy)
                    {
                        /* 011 */
                        /* Left point */
                        z1 = *(magPtr + 1);
                        z2 = *(magPtr - _width + 1);
                        
                        mag1 = (z1 - m00)*xperp + (z2 - z1)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr - 1);
                        z2 = *(magPtr + _width - 1);
                        
                        mag2 = (z1 - m00)*xperp + (z2 - z1)*yperp;
                    }
                    else
                    {
                        /* 010 */
                        /* Left point */
                        z1 = *(magPtr - _width);
                        z2 = *(magPtr - _width + 1);
                        
                        mag1 = (z2 - z1)*xperp + (z1 - m00)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr + _width);
                        z2 = *(magPtr + _width - 1);
                        
                        mag2 = (z2 - z1)*xperp + (z1 - m00)*yperp;
                    }
                }
                else
                {
                    if (-gx > -gy)
                    {
                        /* 001 */
                        /* Left point */
                        z1 = *(magPtr + 1);
                        z2 = *(magPtr + _width + 1);
                        
                        mag1 = (z1 - m00)*xperp + (z1 - z2)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr - 1);
                        z2 = *(magPtr - _width - 1);
                        
                        mag2 = (z1 - m00)*xperp + (z1 - z2)*yperp;
                    }
                    else
                    {
                        /* 000 */
                        /* Left point */
                        z1 = *(magPtr + _width);
                        z2 = *(magPtr + _width + 1);
                        
                        mag1 = (z2 - z1)*xperp + (m00 - z1)*yperp;
                        
                        /* Right point */
                        z1 = *(magPtr - _width);
                        z2 = *(magPtr - _width - 1);
                        
                        mag2 = (z2 - z1)*xperp + (m00 - z1)*yperp;
                    }
                }
            } 
            
            /* Now determine if the current point is a maximum point */
            
            if ((mag1 > 0.0) || (mag2 > 0.0))
            {
                *resultPtr = (unsigned char) NOEDGE;
            }
            else
            {    
                if (mag2 == 0.0)
                    *resultPtr = (unsigned char) NOEDGE;
                else
                    *resultPtr = (unsigned char) POSSIBLE_EDGE;
            }
        } 
    }
}

- (void)gaussianBlur{
    int blurMatrix[5][5] = {
        { 1,  4,  7,  4,  1},
        { 4, 16, 26, 16,  4},
        { 7, 26, 41, 26,  7},
        { 4, 16, 26, 16,  4},
        { 1,  4,  7,  4,  1},
    };
    uint8_t *blurImage = malloc(sizeof(uint8_t) * (_width - 5) * (_height - 5));
    for (int y = 0; y < _height - 5; y++) {
        for (int x = 0; x < _width - 5; x++) {
            int val = 0;
            for (int dy = 0; dy < 5; dy++) {
                for (int dx = 0; dx < 5; dx++) {
                    int pixel = _imageData[(y+dy) * _width + x + dx];
                    val += pixel * blurMatrix[dy][dx];
                }
            }
            blurImage[y*(_width-5)+x] = val/273;
        }
    }
    _width -= 5;
    _height -= 5;
    if (_imageData) {
        free(_imageData);
        _imageData = NULL;
    }
    _imageData = blurImage;
}


//image binarization
- (UIImage *)getBlackImage:(UIImage *)image{
    UIImage *retImg = nil;
    
//    CGSize size = image.size;
//    NSInteger width = size.width;
//    NSInteger height = size.height;
    
    CGImageRef imageRef = [image CGImage];
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *ciImage = [CIImage imageWithCGImage:imageRef];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:
                        @"inputImage", ciImage,
                        @"inputColor", [CIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f],
                        @"inputIntensity", [NSNumber numberWithFloat:1.0f],
                        nil];
    CIImage *filtedImage = [filter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:filtedImage fromRect:[filtedImage extent]];
    retImg = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return retImg;
}

- (UIImage *)getGreyScaleImage:(UIImage *)image{
    
//    int colors = kRed | kGreen | kBlue;
    CGSize size = image.size;
    NSInteger width = size.width;
    NSInteger height = size.height;
    uint32_t *bitMap = (uint32_t *)malloc(width * height * sizeof(uint32_t));
    memset(bitMap, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(bitMap, width, height, 8, width * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, NO);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
    
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            uint8_t *rgbPixel = (uint8_t *)&bitMap[y * width + x];
            //recommended by wiki
            uint32_t gray = 0.3 * rgbPixel[kRed] + 0.59 * rgbPixel[kBlue] + 0.11 * rgbPixel[kBlue];
            rgbPixel[kRed] = gray;
            rgbPixel[kGreen] = gray;
            rgbPixel[kBlue] = gray;
        }
    }
    
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(bitMap);
    bitMap = NULL;
    
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return returnImage;
}

#pragma mark ---------utilities-----------

- (UIImage *)imageFromBitMap{
    UIImage *retImage = nil;
    uint8_t *retImageData = calloc(sizeof(uint32_t) * _width * _height, 1);
    for (int i = 0; i < _height * _width; i++) {
        uint8_t *rgbPixel = (uint8_t *)&retImageData[4*i];
        int pixel = _imageData[i];
        rgbPixel[kRed] = pixel;
        rgbPixel[kGreen] = pixel;
        rgbPixel[kBlue] = pixel;
    }
    
    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
    CGContextRef context=CGBitmapContextCreate(retImageData, _width, _height, 8, _width*sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipLast);
    CGImageRef image=CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    retImage=[UIImage imageWithCGImage:image];
    CGImageRelease(image);
    // make sure the data will be released by giving it to an autoreleased NSData
    [NSData dataWithBytesNoCopy:retImageData length:_width*_height];
    return retImage;
}

@end
