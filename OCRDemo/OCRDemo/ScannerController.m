//
//  OverlayViewController.m
//  OCRDemo
//
//  Created by ltp on 6/14/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "ScannerController.h"
#import <AVFoundation/AVFoundation.h>
#import "LibOCR.h"
#import "CameraOverlay.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define ColorHex(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 green:((c>>8)&0xFF)/255.0 blue:((c)&0xFF)/255.0 alpha:1.0]

static NSMutableArray<LetterPosition*> *letterPosArray;     //position of passport letters
static NSMutableArray<LetterPosition*> *numPosArray;        //position of id card numbers
static bool needAdjust;     //whether the position of letters should be adjusted

//get position of 88 letters
void saveLetterPos(int *pos){
    NSLock *arrayLock = [[NSLock alloc] init];
    [arrayLock lock];
    
    if (letterPosArray) {
        [letterPosArray removeAllObjects];
    }
    else {
        letterPosArray = [NSMutableArray array];
    }
    for (int i = 0; i < 88; i++) {
        LetterPosition *tmpLetterPos = [[LetterPosition alloc] init];
        if (IS_IPHONE_4_OR_LESS && !SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            //in iphone4 with ios7, the picture is not cropped correctly
            tmpLetterPos.x = ((needAdjust)?-50:0) + pos[i * 4];
        }
        else
            tmpLetterPos.x = ((needAdjust)?-30:0) + pos[i * 4];
        tmpLetterPos.y = pos[i * 4 + 1];
        if (IS_IPHONE_4_OR_LESS && !SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            tmpLetterPos.toX = ((needAdjust)?-40:0) + pos[i * 4 + 2];
        }
        else
            tmpLetterPos.toX = ((needAdjust)?-20:0) + pos[i * 4 + 2];
        tmpLetterPos.toY = pos[i * 4 + 3];
        [letterPosArray addObject:tmpLetterPos];
    }
    //release memory
    [arrayLock unlock];
}

//get position of id card numbers
void saveNumPos(int *pos){
    NSLock *arrayLock = [[NSLock alloc] init];
    [arrayLock lock];
    
    if (numPosArray) {
        [numPosArray removeAllObjects];
    }
    else {
        numPosArray = [NSMutableArray array];
    }
    for (int i = 0; i < 18; i++) {
        LetterPosition *tmpLetterPos = [[LetterPosition alloc] init];
        if (IS_IPHONE_4_OR_LESS && !SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            //in iphone4 with ios7, the picture is not cropped correctly
            tmpLetterPos.x = ((needAdjust)?-50:0) + pos[i * 4];
        }
        else
            tmpLetterPos.x = ((needAdjust)?-30:0) + pos[i * 4];
        tmpLetterPos.y = pos[i * 4 + 1];
        if (IS_IPHONE_4_OR_LESS && !SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            tmpLetterPos.toX = ((needAdjust)?-40:0) + pos[i * 4 + 2];
        }
        else
            tmpLetterPos.toX = ((needAdjust)?-20:0) + pos[i * 4 + 2];
        tmpLetterPos.toY = pos[i * 4 + 3];
        [numPosArray addObject:tmpLetterPos];
    }
    //release memory
    [arrayLock unlock];
}
//
//int getPixelByCharImage(int *arr, int num, int x, int y){
//    int a = arr[num * 25 + (y * 13 + x)/8];
//    return  (a >> (7 - (y * 13 + x) % 8))&1;
//}
//
//char getCharByInt(int maxI){
//    if (maxI < 10) {
//        char a = (char)(48 + maxI);
//        return a;
//    }
//    else if(maxI == 31){
//        return '<';
//    }
//    return (char)(55 + maxI);
//}
//
//void saveSmallBitmap(int* arr){
//    for (int i = 0; i < 88; i++) {
////        int value = arr[2200 + i];
//        int32_t *bitMap;
//        bitMap = malloc(13 * 15 * sizeof(int32_t));
//        for (int j = 0; j < 13; j++) {
//            for (int k = 0; k < 15; k++) {
//                if (getPixelByCharImage(arr, i, j, k)) {
//                    bitMap[j * 15 + k] = 0xff000000;
//                }
//                else
//                    bitMap[j * 15 + k] = 0xffffffff;
//            }
//        }
//        CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
//        CGContextRef bitmapContext=CGBitmapContextCreate(bitMap, 13, 15, 8, 4*13, colorSpace,  kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrderDefault);
//        CFRelease(colorSpace);
//        free(bitMap);
//        CGImageRef cgImage=CGBitmapContextCreateImage(bitmapContext);
//        CGContextRelease(bitmapContext);
//        
//        UIImage *newimage = [UIImage imageWithCGImage:cgImage];
//        CGImageRelease(cgImage);
//        free(bitMap);
//    }
//}
//
//int getPixelByBlackImage(int32_t *arr, int x, int y){
//    uint32_t tmpInt = arr[y * 88 + x / 8];
//    return (tmpInt>>(7 - x % 8)) & 1;
//}
//
//void saveBitmap(int* arr){
//    int32_t *bitMap;
//    bitMap = malloc(131 * 700 * sizeof(int32_t));
//    for (int i = 0; i < 700; i++) {
//        for (int j = 0; j < 131; j++) {
//            if (getPixelByBlackImage(arr, i, j) != 0) {
//                bitMap[j * 700 + i] = 0xff000000;
//            }
//            else
//                bitMap[j * 700 + i] = 0xffffffff;
//        }
//    }
//    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
//    CGContextRef bitmapContext=CGBitmapContextCreate(bitMap, 700, 131, 8, 4*700, colorSpace,  kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrderDefault);
//    CFRelease(colorSpace);
//    CGImageRef cgImage=CGBitmapContextCreateImage(bitmapContext);
//    CGContextRelease(bitmapContext);
//    
//    UIImage *newimage = [UIImage imageWithCGImage:cgImage];
//    free(bitMap);
//    CGImageRelease(cgImage);
//}

@interface ScannerController ()<AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) PassportScanResult *resultModel;

/**
 **  ATTENTION: please set the desired scannerType before present view controller, otherwise the scanner controller will use default type, i.e., idCardScanner, for now.
 **/
@property (nonatomic, assign) ScannerType scannerType;

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation ScannerController{
    UIView *_tipView;
    UIView *_OCRFailureAlert;
    CameraOverlay *_overlay;
//    CameraOverlay *_idCardOverlay;
    AVCaptureVideoPreviewLayer *_previewLayer;
    NSLock *_lock;
    UIPinchGestureRecognizer *_pinchRecognizer;
    UIRotationGestureRecognizer *_rotationRecognizer;
    UIPanGestureRecognizer *_panRecognizer;
    UIView *_imageContainer;
    ImageSourceType _imageSource;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self initView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    static BOOL firstTime = TRUE;   //only automatically show if the app enters for the first time
    if (firstTime) {
        [self.view addSubview:_tipView];
        firstTime = NO;
    }
    if (_imageSource == ImageSourceByCapturing ) {
        if ([self checkCameraAccess]) {
            [_captureSession startRunning];
            [self.view.layer insertSublayer:_previewLayer atIndex:0];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:true];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)initObServer{
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleError:) name:AVCaptureSessionRuntimeErrorNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVCaptureSessionWasInterruptedNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:nil];
//}

#pragma mark -------------  initialization   -------------------

- (void)initView{
    if (!_previewLayer) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    }
    CGRect bounds = self.view.layer.bounds;
    _previewLayer.bounds = bounds;
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_previewLayer setPosition:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
    
    [self initOverlayView];
    [self initTipView];
    _imageContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self.view addSubview:_imageContainer];
    [self.view sendSubviewToBack:_imageContainer];
    _imageView = [[UIImageView alloc] init];
    [_imageContainer addSubview:_imageView];
    [self.view addSubview:_overlay];
    [self initOCRFailureAlert];
    
}

- (void)initData{
    if (!_scannerType) {
        _scannerType = PassportScanner;
    }
    if (!_rotationRecognizer) {
        _rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotate:)];
    }
    if (!_pinchRecognizer) {
        _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    }
    if (!_panRecognizer) {
        _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    }
    [self initCapture];
    _lock = [[NSLock alloc] init];
    needAdjust = true;
    _imageSource = ImageSourceByCapturing;
}

- (void)initCapture{
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    if (!captureInput) {
        return;
    }
    AVCaptureDeviceFormat *bestFormat = nil;
    AVFrameRateRange *bestFrameRateRange = nil;
    for (AVCaptureDeviceFormat *format in [captureDevice formats]) {
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            if (!bestFrameRateRange) {
                bestFrameRateRange = range;
                bestFormat = format;
            }
            if (range.minFrameRate < bestFrameRateRange.minFrameRate) {
                bestFormat = format;
                bestFrameRateRange = range;
            }
        }
    }
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = true;
    dispatch_queue_t sessionQueue = dispatch_queue_create("cameraQueue", NULL);
    _captureSession = [[AVCaptureSession alloc] init];
    
    [_captureSession beginConfiguration];
    if (bestFormat) {
        if ([captureDevice lockForConfiguration:nil] == YES) {
            captureDevice.activeFormat = bestFormat;
            captureDevice.activeVideoMaxFrameDuration = bestFrameRateRange.minFrameDuration;
            captureDevice.activeVideoMinFrameDuration = bestFrameRateRange.minFrameDuration;
            [captureDevice unlockForConfiguration];
        }
    }
    [captureOutput setSampleBufferDelegate:self queue:sessionQueue];
    [captureOutput setAlwaysDiscardsLateVideoFrames:YES];
    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInteger:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
    NSDictionary *videoSetting = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSetting];
    NSString *preset = 0;
    if (!preset) {
        if ([captureDevice supportsAVCaptureSessionPreset:AVCaptureSessionPresetHigh]) {
            preset = AVCaptureSessionPresetHigh;
        }
        else
            preset = AVCaptureSessionPresetMedium;
    }
    _captureSession.sessionPreset = preset;
    if ([_captureSession canAddInput:captureInput]) {
        [_captureSession addInput:captureInput];
    }
    if ([_captureSession canAddOutput:captureOutput]) {
        [_captureSession addOutput:captureOutput];
    }
    [_captureSession commitConfiguration];
}

- (void)initOCRFailureAlert{
    float scaleRatio = [UIScreen mainScreen].bounds.size.width / 375;
    _OCRFailureAlert = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [_OCRFailureAlert setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.7]];
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300 * scaleRatio, 144 * scaleRatio)];
    CGSize size = container.frame.size;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15 * scaleRatio, 27 * scaleRatio, size.width - 30 * scaleRatio, 24)];
    title.textAlignment = NSTextAlignmentCenter;
    [title setText:@"识别失败"];
    title.textColor = [UIColor blackColor];
    title.font = [UIFont boldSystemFontOfSize:17.0f];
    [container addSubview:title];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15 * scaleRatio, title.frame.origin.y + title.frame.size.height + 6 * scaleRatio, size.width - 30 * scaleRatio, 16 * scaleRatio)];
    [label setText:@"请确保证件有效，且图片清晰无变形"];
    label.font = [UIFont systemFontOfSize:13.0f];
    label.textAlignment = NSTextAlignmentCenter;
    [container addSubview:label];
    
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, size.height - 44 * scaleRatio, size.width / 2, 44 *scaleRatio)];
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:ColorHex(0x099FDE) forState:UIControlStateNormal];
    [cancelBtn addTarget:_OCRFailureAlert action:@selector(removeFromSuperview) forControlEvents:UIControlEventTouchUpInside];
    cancelBtn.layer.borderColor = ColorHex(0xCDCED2).CGColor;
    cancelBtn.layer.borderWidth = 1.0f;
    cancelBtn.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    [container addSubview:cancelBtn];
    
    UIButton *repickBtn = [[UIButton alloc] initWithFrame:CGRectMake(size.width / 2, size.height - 44 * scaleRatio, size.width / 2, 44 *scaleRatio)];
    [repickBtn setTitle:@"重选图片" forState:UIControlStateNormal];
    [repickBtn setTitleColor:ColorHex(0x099FDE) forState:UIControlStateNormal];
    [repickBtn addTarget:self action:@selector(choosePicture) forControlEvents:UIControlEventTouchUpInside];
    repickBtn.layer.borderColor = ColorHex(0xCDCED2).CGColor;
    repickBtn.layer.borderWidth = 1.0f;
    repickBtn.titleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    [container addSubview:repickBtn];
    
    container.backgroundColor = [UIColor whiteColor];
    container.clipsToBounds = YES;
    container.layer.cornerRadius = 13.0f;
    container.transform = CGAffineTransformMakeRotation(M_PI/2);
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    container.frame = CGRectMake((screenSize.width - size.height) / 2, (screenSize.height - size.width) / 2, size.height, size.width);
    [_OCRFailureAlert addSubview:container];
}

- (void)initTipView{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat width = screenSize.width;
    CGFloat height = screenSize.height;
    UIView *containerView = [[UIView alloc] init];
    
    _tipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        _tipView.backgroundColor = [UIColor clearColor];
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = _tipView.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_tipView addSubview:blurEffectView];
    }
    else {
        _tipView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    }
    UILabel *tips = [[UILabel alloc] init];
    tips.numberOfLines = 0;
    tips.font = [UIFont systemFontOfSize:15.0];
    tips.textColor = [UIColor whiteColor];
    tips.text = @"      请确保：\n\n\
    \u2022 证件为有效证件\n\n\
    \u2022 扫描角度正对证件，无倾斜、无抖动\n\n\
    \u2022 证件无反光且清晰。若灯光过暗，请打开闪光灯\n\n\
      或至明亮的地方扫描\n\n\
    \u2022 网络顺畅";
    CGSize labelSize = [tips.text sizeWithAttributes:@{NSFontAttributeName:tips.font}];
    tips.frame = CGRectMake(0, 0, labelSize.width, labelSize.height);
    [containerView addSubview:tips];
    
    UIButton *okButton = [[UIButton alloc] initWithFrame:CGRectMake(tips.frame.origin.x + (labelSize.width - 254)/2, tips.frame.origin.y + labelSize.height + 60, 254, 44)];
    [okButton setTitle:@"知道了" forState:UIControlStateNormal];
    [okButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [okButton.titleLabel setFont:[UIFont systemFontOfSize:18.0]];
    [okButton setBackgroundColor:[UIColor clearColor]];
    [okButton addTarget:self action:@selector(dismissTipView) forControlEvents:UIControlEventTouchUpInside];
    okButton.layer.borderWidth = 0.5f;
    okButton.layer.borderColor = [UIColor whiteColor].CGColor;
    okButton.layer.cornerRadius = 4.0f;
    [containerView addSubview:okButton];
    
    [containerView setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    containerView.frame = CGRectMake((width - labelSize.height - 60 - okButton.frame.size.height) / 2, (height - labelSize.width) / 2, labelSize.height + okButton.frame.size.height + 60, MAX(labelSize.width, okButton.frame.size.width));
    [_tipView addSubview:containerView];
}

- (void)initOverlayView{
    _overlay = [[CameraOverlay alloc] init];
    _overlay.frame = [UIScreen mainScreen].bounds;
    __weak typeof(self) weakSelf = self;
    _overlay.tapFlashLight = ^(UIButton *btn){
        __weak typeof(weakSelf) self = weakSelf;
        [self flashLight];
    };
    _overlay.dismissImagePicker = ^{
        __weak typeof(weakSelf) self = weakSelf;
        [self back];
    };
    _overlay.tapTip = ^{
        __weak typeof(weakSelf) self = weakSelf;
        [self showTip];
    };
    _overlay.doOCR = ^{
        __weak typeof(weakSelf) self = weakSelf;
        [self OCR];
    };
    _overlay.tapIDCardBtn = ^{
        __weak typeof(weakSelf) self = weakSelf;
        self.scannerType = IDCardScanner;
    };
    _overlay.tapPassportBtn = ^{
        __weak typeof(weakSelf) self = weakSelf;
        self.scannerType = PassportScanner;
    };
    _overlay.doTakingPicture = ^{
        __weak typeof(weakSelf) self = weakSelf;
        [self takePicture];
    };
    _overlay.doChoosePicture = ^{
        __weak typeof(weakSelf) self = weakSelf;
        [self choosePicture];
        [self addOverlayRecognizers];
        needAdjust = false;
    };
}

#pragma mark  -------------------  utility  -----------------

- (void)OCR{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(_imageContainer.bounds.size, NO, [UIScreen mainScreen].scale);
    }
    else
        UIGraphicsBeginImageContext(_imageContainer.bounds.size);
    
    [_imageContainer.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

//    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,image.size.width, image.size.height)];
//    rotatedViewBox.transform = CGAffineTransformMakeRotation(-M_PI_2);
//    CGSize rotatedSize = rotatedViewBox.frame.size;
//    
//    // Create the bitmap context
//    UIGraphicsBeginImageContext(rotatedSize);
//    CGContextRef bitmap = UIGraphicsGetCurrentContext();
//    
//    // Move the origin to the middle of the image so we will rotate and scale around the center.
//    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
//    
//    //   // Rotate the image context
//    CGContextRotateCTM(bitmap, -M_PI_2);
//    
//    // Now, draw the rotated/scaled image into the context
//    CGContextScaleCTM(bitmap, 1.0, -1.0);
//    CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height), [image CGImage]);
//    
//    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
    UIView *imageBox = [[UIView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    imageBox.transform = CGAffineTransformMakeRotation(-M_PI_2);
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(imageBox.frame.size, NO, [UIScreen mainScreen].scale);
    }
    else
        UIGraphicsBeginImageContext(imageBox.frame.size);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(bitmap, imageBox.frame.size.width / 2, imageBox.frame.size.height / 2);
    CGContextRotateCTM(bitmap, -M_PI_2);
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height/2, image.size.width, image.size.height), [image CGImage]);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
//    int8_t *byteArray;
//    byteArray = malloc(newImage.size.height * newImage.size.width * sizeof(int8_t));
//    memcpy(byteArray, [UIImageJPEGRepresentation(newImage, 1.0) bytes], newImage.size.height * newImage.size.width);
    CGImageRef imageRef = newImage.CGImage;
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    int8_t *rawData = calloc(height * width * 4, sizeof(int8_t));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    NSData *data = UIImageJPEGRepresentation(newImage, 1.0);
    if (_scannerType == PassportScanner) {
        [self passportOCR:rawData width:newImage.size.width height:newImage.size.height image:newImage];
    }
    else if (_scannerType == IDCardScanner) {
        [self IDCardOCR:rawData width:newImage.size.width height:newImage.size.height image:newImage];
    }
}

- (void)presentScanner:(ScannerType)scannerType imageSource:(ImageSourceType)imageSourceType inViewController:(UIViewController *)vc{
    [vc presentViewController:self animated:YES completion:nil];
//    _scannerType = scannerType;
//    _imageSource = imageSourceType;
//    switch (scannerType) {
//        case PassportScanner:{
//            if ([_idCardOverlay superview]) {
//                [_idCardOverlay removeFromSuperview];
//            }
//            [self.view addSubview:_passportOverlay];
//        }
//            break;
//        case IDCardScanner:{
//            if ([_passportOverlay superview]) {
//                [_passportOverlay removeFromSuperview];
//            }
//            [self.view addSubview:_idCardOverlay];
//        }
//        default:
//            break;
//    }
    
//    static BOOL firstTime = TRUE;   //only automatically show if the app enters for the first time
//    switch (imageSourceType) {
//        case ImageSourceByCapturing:
//            needAdjust = true;
//            [self.view.layer insertSublayer:_previewLayer atIndex:0];
//            [_captureSession startRunning];
//            if (firstTime) {
//                [self.view addSubview:_tipView];
//                firstTime = NO;
//            }
//            break;
//            
//        case ImageSourceByChoosing:
//            needAdjust = false;
//            [(scannerType == PassportScanner)?_passportOverlay:_idCardOverlay addGestureRecognizer:_rotationRecognizer];
//            [(scannerType == PassportScanner)?_passportOverlay:_idCardOverlay addGestureRecognizer:_pinchRecognizer];
//            [(scannerType == PassportScanner)?_passportOverlay:_idCardOverlay addGestureRecognizer:_panRecognizer];
//            
//            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
//                UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
//                pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//                pickerController.delegate = self;
//                pickerController.allowsEditing = NO;
//                [self presentViewController:pickerController animated:YES completion:nil];
//            }
//            [self.view bringSubviewToFront:_btn];
//            [_imageContainer addSubview:_imageView];
//            break;
//            
//        default:
//            break;
//    }
}

- (void)handleRotate:(UIRotationGestureRecognizer *)recognizer{
    _imageView.transform = CGAffineTransformRotate(_imageView.transform, recognizer.rotation);
    recognizer.rotation = 0;
}

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer{
    _imageView.transform = CGAffineTransformScale(_imageView.transform, recognizer.scale, recognizer.scale);
    recognizer.scale = 1;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer{
    if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:self.view];
        CGPoint translatedCenter = CGPointMake(_imageView.center.x + translation.x, _imageView.center.y + translation.y);
        _imageView.center = translatedCenter;
        [recognizer setTranslation:CGPointZero inView:self.view];
    }
}

- (void)takePicture{
    if (self.imageView) {
        [self.imageView removeFromSuperview];
    }
    [self removeOverlayRecognizers];
    needAdjust = true;
    _imageSource = ImageSourceByCapturing;
    [self.view.layer insertSublayer:_previewLayer atIndex:0];
    
    if (![self.captureSession isRunning]) {
        [self.captureSession startRunning];
    }
}

- (void)choosePicture{
    if ([_OCRFailureAlert superview]) {
        [_OCRFailureAlert removeFromSuperview];
    }
    if ([self.captureSession isRunning]) {
        [self.captureSession stopRunning];
    }
    _imageSource = ImageSourceByChoosing;
    [_previewLayer removeFromSuperlayer];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
        pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        pickerController.delegate = self;
        pickerController.allowsEditing = NO;
        [self presentViewController:pickerController animated:YES completion:nil];
    }
    [_imageContainer addSubview:_imageView];
}

- (void)removeOverlayRecognizers{
    if ([_overlay gestureRecognizers].count > 0) {
        [_overlay removeGestureRecognizer:_rotationRecognizer];
        [_overlay removeGestureRecognizer:_pinchRecognizer];
        [_overlay removeGestureRecognizer:_panRecognizer];
    }
}

- (void)addOverlayRecognizers{
    [self removeOverlayRecognizers];
    [_overlay addGestureRecognizer:_rotationRecognizer];
    [_overlay addGestureRecognizer:_pinchRecognizer];
    [_overlay addGestureRecognizer:_panRecognizer];
}

- (void)dismissTipView{
    [_tipView removeFromSuperview];
}

- (void)flashLight{
    AVCaptureDevice *flashLight = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([flashLight isTorchAvailable] && [flashLight isTorchModeSupported:AVCaptureTorchModeOn]) {
        BOOL success = [flashLight lockForConfiguration:nil];
        if (success) {
            if ([flashLight isTorchActive] || flashLight.torchMode == AVCaptureTorchModeOn) {
                [flashLight setTorchMode:AVCaptureTorchModeOff];
            }
            else {
                [flashLight setTorchMode:AVCaptureTorchModeOn];
            }
            [flashLight unlockForConfiguration];
        }
    }
}

- (void)back{
    if (_imageSource == ImageSourceByChoosing) {
        [_overlay cancelPhotoScanningMode];
        _imageContainer.backgroundColor = [UIColor clearColor];
    }

    if ([_captureSession isRunning]) {
        [_captureSession stopRunning];
    }
    if (_imageView) {
        [_imageView removeFromSuperview];
    }
    [self removeOverlayRecognizers];
    [self dismissTipView];
    [_previewLayer removeFromSuperlayer];
    if ([self presentingViewController] != nil) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)showTip{
    [self.view addSubview:_tipView];
}

- (BOOL)checkCameraAccess{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
            AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            //    获取对摄像头的访问权限。
            if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)
            {
                UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"请进入系统“设置>隐私>相机”开启此权限" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
                [alertView show];
                return false;
            }
        }//IOS7（包括）之后才有 隐私里面增加 相机。之前版本 只要isSourceTypeAvailable 就可以
    } else {
        return false;
    }
    return true;
}


#pragma mark -------------  UIImagePickerControllerDelegate   -------------------
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [_imageView setImage:image];
    _imageView.transform = CGAffineTransformMakeRotation(M_PI/2);
    float scaleRatio = image.size.width / [UIScreen mainScreen].bounds.size.height;
    _imageView.frame = CGRectMake(0, 0, image.size.height / scaleRatio, image.size.width / scaleRatio);
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
    _imageSource = ImageSourceByCapturing;
    [_overlay cancelPhotoScanningMode];
}

#pragma mark ------------- UIGestureRecognizerDelegate   -------------------

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return true;
}

#pragma mark -------------AVCaptureVideoDataOutputSampleBufferDelegate   -------------------

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    @synchronized (self) {
        CIImage *ciimage = [CIImage imageWithCVPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];
        CIImage *croppedRecImage = nil;
        CGRect rectangleRect = CGRectZero;
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            
            CIDetector *rectangleDetector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:[CIContext contextWithOptions:nil] options:nil];
            NSArray *rectangleFeatures = [rectangleDetector featuresInImage:ciimage options:nil];
            for (CIFeature *feature in rectangleFeatures) {
                if ( ![feature isKindOfClass:[CIRectangleFeature class]]) {
                    continue;
                }
                
                CIVector *cropRect = [CIVector vectorWithCGRect:feature.bounds];
                CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
                [cropFilter setValue:ciimage forKey:@"inputImage"];
                [cropFilter setValue:cropRect forKey:@"inputRectangle"];
                croppedRecImage = [cropFilter valueForKey:@"outputImage"];
                rectangleRect = feature.bounds;
            }
        }
        else {//for system version less than 8.0, there is no rectangle detector, so the cropped rect need to be fixed.
            croppedRecImage = ciimage;
            CGSize imageSize = ciimage.extent.size;
            float scaleRatio = imageSize.height / 320;
            switch (_scannerType) {
                case IDCardScanner:{
                    ;
                }
                    break;
                case PassportScanner:{
                    CGRect passportRect = CGRectMake((imageSize.width - 354 * scaleRatio) / 2, (imageSize.height - 249 * scaleRatio) / 2, 354 * scaleRatio, 249 * scaleRatio);
                    rectangleRect = passportRect;
                }
                default:
                    break;
            }
        }
        if (croppedRecImage) {
//            BOOL faceDetected = FALSE;
//            CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:[CIContext contextWithOptions:nil] options:nil];
//            NSArray *faceFeatures = [faceDetector featuresInImage:croppedRecImage options:nil];
  //          for (CIFeature *feature in faceFeatures) {
    //            if ( [feature isKindOfClass:[CIFaceFeature class]]) {
      //              faceDetected = YES;
        //            break;
          //      }
            //}
            //if (!faceDetected) {
              //  return;
            //}
            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            CVPixelBufferLockBaseAddress(imageBuffer, 0);
            void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
            //                size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
            size_t width = CVPixelBufferGetWidth(imageBuffer);
            size_t height = CVPixelBufferGetHeight(imageBuffer);
            size_t size = CVPixelBufferGetDataSize(imageBuffer);
            int8_t *byteMap = malloc(size * sizeof(int8_t) - 16);
            memcpy(byteMap, baseAddress + 16, size);
            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
            CGImageRef tmpImageRef = [[CIContext contextWithOptions:nil] createCGImage:ciimage fromRect:ciimage.extent];
            UIImage *wholeImage = [UIImage imageWithCGImage:tmpImageRef];
            CGImageRelease(tmpImageRef);
            
            switch (_scannerType) {
                case PassportScanner:
                    [self passportOCR:byteMap width:(int)width height:(int)height image:(UIImage*)wholeImage];
                    break;
                case IDCardScanner:
                    [self IDCardOCR:byteMap width:(int)width height:(int)height image:(UIImage*)wholeImage];
                default:
                    break;
            }
            
        }
        
    }
}

-(void)IDCardOCR:(int8_t *)imageData width:(int)width height:(int)height image:(UIImage*)image{
    @autoreleasepool {
        if ([_lock tryLock]) {
            //105/330 = 0.318 (105:length of "公民身份号码"   330:length of id card)
            //55/208 = 0.264 (55:height of rect in which the id number possibly exists   208:height of id card)
            float scaleRatio = image.size.height * image.scale / 320;
            CGSize imageSize = image.size;
            CGRect cardRect = CGRectMake((imageSize.width * image.scale - 365 * scaleRatio) / 2, (imageSize.height * image.scale - 232 * scaleRatio) / 2, 365 * scaleRatio, 232 * scaleRatio);

            CGSize possibleSize = CGSizeMake(cardRect.size.width - cardRect.size.width * 0.318, cardRect.size.height * 0.244);  //minimze 0.264 to 0.244 to raise accuracy
            CGRect croppedRect  = CGRectMake(cardRect.origin.x + cardRect.size.width - possibleSize.width, cardRect.origin.y + cardRect.size.height - possibleSize.height, possibleSize.width, possibleSize.height);
            CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], croppedRect);
            UIImage *newImage = [UIImage imageWithCGImage:imageRef];//[UIImage imageWithData:tmpData];//
            CGImageRelease(imageRef);
            
            int bytesPerPixel = (_imageSource == ImageSourceByChoosing)?4:1;
            char *result = libOCRScanIDCard(imageData, width*image.scale*bytesPerPixel, height*image.scale, croppedRect.origin.x*bytesPerPixel, croppedRect.origin.y, croppedRect.size.width*bytesPerPixel, croppedRect.size.height);
            NSString *scanResult = (*result)?[NSString stringWithUTF8String:result]:@"";
            free(result);
            if (scanResult.length >= 18) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"result"
                                                                message:scanResult
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                if ([_captureSession isRunning]) {
                    [_captureSession stopRunning];
                }
                IDCardScanResult *resultModel = [[IDCardScanResult alloc] initWithScanResult:scanResult];
                [resultModel cropImage:image inRect:cardRect withPositions:numPosArray];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alert show];
                    if ([_IDCardDelegate respondsToSelector:@selector(IDCardScannerDidFinish:)]) {
                        [_IDCardDelegate IDCardScannerDidFinish:resultModel];
                    }
                });
            }
            else if (_imageSource == ImageSourceByChoosing){
                [self.view addSubview:_OCRFailureAlert];
            }
            [_lock unlock];
        }
        free(imageData);
    }
}

-(void)passportOCR:(int8_t *)imageData width:(int)width height:(int)height image:(UIImage*)image{//125*88
    @autoreleasepool {
        if ([_lock tryLock]) {
            float scaleRatio = image.size.height * image.scale / 320;
            CGSize imageSize = image.size;
            CGRect passportRect = CGRectMake((imageSize.width * image.scale - 354 * scaleRatio) / 2, (imageSize.height * image.scale - 249 * scaleRatio) / 2, 354 * scaleRatio, 249 * scaleRatio);
            CGRect croppedRect  = CGRectMake(passportRect.origin.x, passportRect.origin.y + passportRect.size.height - passportRect.size.width * 0.158, passportRect.size.width, passportRect.size.width * 0.158);
            CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], croppedRect);
            UIImage *newImage = [UIImage imageWithCGImage:imageRef];//[UIImage imageWithData:tmpData];//
            CGImageRelease(imageRef);
            
            int bytesPerPixel = (_imageSource == ImageSourceByChoosing)?4:1;
            char *result = libOCRScanPassport(imageData, width*image.scale*bytesPerPixel, height*image.scale, croppedRect.origin.x*bytesPerPixel, croppedRect.origin.y, croppedRect.size.width*bytesPerPixel, croppedRect.size.height); //0.158 = 1/6.33
            NSString *scanResult = (result)?[NSString stringWithUTF8String:result]:@"";
                free(result);
            if (scanResult && scanResult.length >= 88) {
                PassportScanResult *resultModel = [[PassportScanResult alloc] initWithScanResult:scanResult];
                if (resultModel.gotLegalData) {
                    if ([_captureSession isRunning]) {
                        [_captureSession stopRunning];
                    }
                    //crop image for user to validate the information extracted from the scanning
                    [resultModel cropImage:image inRect:passportRect withPositions:letterPosArray];
                    NSString *showResult = [NSString stringWithFormat:@"family name:\t%@\ngiven name:\t%@\npassportID:\t%@\nnation:\t%@gender:\t%@",
                                            resultModel.familyName,
                                            resultModel.givenName,
                                            resultModel.passportID,
                                            resultModel.nation,
                                            (resultModel.gender == 0)?@"女":@"男"
                                            ];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"result"
                                                                    message:showResult
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [alert show];
                        if ([_passportDelegate respondsToSelector:@selector(PassportScannerDidFinish:)]) {
                            [_passportDelegate PassportScannerDidFinish:resultModel];
                        }
                    });
                }
                else if (_imageSource == ImageSourceByChoosing){
                    [self.view addSubview:_OCRFailureAlert];
                }
            }
            else if (_imageSource == ImageSourceByChoosing){
                [self.view addSubview:_OCRFailureAlert];
            }
            NSLog(@"%@", scanResult);
            [_lock unlock];
        }
        free(imageData);
    }
}

@end
