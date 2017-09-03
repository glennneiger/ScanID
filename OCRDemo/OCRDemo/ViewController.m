//
//  ViewController.m
//  IDRecognitionDemo
//
//  Created by alex on 16/4/16.
//  Copyright © 2016年 ctrip. All rights reserved.
//

#import "ViewController.h"
#import <TesseractOCR/TesseractOCR.h>
#import "CardIO.h"
#import "CardIOUtilities.h"
#import "OCRManager.h"
//#import "CameraOverlay.h"
#import "AppDelegate.h"
#import "ScannerController.h"

#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height
#define kButtonRadius 50
#define kPicSideLength [[UIScreen mainScreen] bounds].size.width/2

static inline UIImageView *demoImageView (UIImage *pic, NSInteger index) {
    UIImageView *ret = [[UIImageView alloc] initWithImage:pic];
    int y = index / 2 * kPicSideLength;
    int x = index % 2 * kPicSideLength;
    ret.frame = CGRectMake(x , y, kPicSideLength, kPicSideLength);
    return ret;
}

@interface ViewController () <UINavigationControllerDelegate,UIImagePickerControllerDelegate, G8TesseractDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImageView *picView;
@property (strong, nonatomic) UIImageView *greyView;
@property (strong, nonatomic) UIImageView *blackView;
@property (strong, nonatomic) UIImageView *edgeView;
@end

@implementation ViewController {
    G8Tesseract *_tesseract;
    NSString *_recognizedText;
    ScannerController *_scannerController;
    ImageSourceType _imageSource;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([CardIOUtilities canReadCardWithCamera]) {
        
    }
    
    [self initView];
    [self setupImagePicker];
//    [self configTesseract];
}

- (void)takePhoto{
    [self presentViewController:_scannerController animated:YES completion:nil];

 //   _imageSource = ImageSourceByCapturing;
//    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"身份证", @"护照", nil];
//    [actionSheet showInView:self.view];
}

- (void)pickPhoto{
        [self presentViewController:_scannerController animated:YES completion:nil];
    //_imageSource = ImageSourceByChoosing;
    //UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"身份证", @"护照", nil];
    //[actionSheet showInView:self.view];
//    [_scannerController presentScanner:PassportScanner imageSource:ImageSourceByChoosing inViewController:self];
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"ID Number" message:_recognizedText preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
//    [alertController addAction:okAction];
//    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    [((AppDelegate *)[UIApplication sharedApplication].delegate) setRotateLeft:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    self.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    
//    _tesseract.image = [self.image g8_blackAndWhite];
//    [self.picView setImage:_tesseract.image];
//    _tesseract.rect = CGRectMake(0, 0, _tesseract.image.size.width, _tesseract.image.size.height);
//    if ([_tesseract recognize]) {
//        _recognizedText = [_tesseract recognizedText];
//    }
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}

-(void)initView {
    self.navigationController.navigationBarHidden = YES;
    [self.view setBackgroundColor:[UIColor purpleColor]];
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth/2 - kButtonRadius, kScreenHeight - kButtonRadius * 2, kButtonRadius * 2, kButtonRadius * 2)];
    btn.backgroundColor = [UIColor blackColor];
    [btn setTitle:@"camera" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
    btn.layer.cornerRadius = kButtonRadius;
    [self.view addSubview:btn];
    
    UIButton *albumBtn = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth/2 - kButtonRadius, kScreenHeight - kButtonRadius * 4, kButtonRadius * 2, kButtonRadius * 2)];
    albumBtn.backgroundColor = [UIColor redColor];
    [albumBtn addTarget:self action:@selector(pickPhoto) forControlEvents:UIControlEventTouchUpInside];
    albumBtn.layer.cornerRadius = kButtonRadius;
    [albumBtn setTitle:@"album" forState:UIControlStateNormal];
    [self.view addSubview:albumBtn];
    
    _image = [UIImage imageNamed:@"passport.jpg"];
    self.picView = demoImageView(_image, 0);
    [self.view addSubview:self.picView];
    
    OCRManager *ocrManager = [[OCRManager alloc] init];
    UIImage *greyImg = [ocrManager getGreyScaleImage:_image];
    _greyView = demoImageView(greyImg, 1);
    [self.view addSubview:_greyView];
    
    UIImage *blackImg = [ocrManager getBlackImage:greyImg];
    _blackView = demoImageView(blackImg, 2);
    [self.view addSubview:_blackView];
    
    UIImage *edgeImg = [ocrManager getEdge:_image];
    _edgeView = demoImageView(edgeImg, 3);
    [self.view addSubview:_edgeView];
}

- (void)back{
    [_imagePicker dismissViewControllerAnimated:YES completion:nil];
}

-(void)setupImagePicker {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
//        self.imagePicker = [[UIImagePickerController alloc] init];
//        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
////        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
//        self.imagePicker.allowsEditing = NO;
//        self.imagePicker.delegate = self;
//        _imagePicker.showsCameraControls = NO;
//        _imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
//        _imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
//        
        _scannerController = [[ScannerController alloc] init];
//        _imagePicker.cameraOverlayView = _scannerController.view;

        //make iamge picker full screen
//        CGSize screenSize = [UIScreen mainScreen].bounds.size;
//        float cameraAspectRatio = 4.0 / 3.0;
//        float imageHeight = floorf(screenSize.width * cameraAspectRatio);
//        float scale = ceilf((screenSize.height / imageHeight) * 10.0) / 10.0;
//        _imagePicker.cameraViewTransform = CGAffineTransformMakeTranslation(0, (screenSize.height - imageHeight) / 2);
//        _imagePicker.cameraViewTransform = CGAffineTransformScale(_imagePicker.cameraViewTransform,scale, scale);
    }
}

-(void)configTesseract {
    _tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
    _tesseract.delegate = self;
    _tesseract.charWhitelist = @"0123456789";
    _tesseract.maximumRecognitionTime = 5.0;
}

#pragma mark  ---- tesseract delegate ----
- (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    NSLog(@"progress: %lu", (unsigned long)tesseract.progress);
}

- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    return NO;
}

#pragma mark ------------------- UIActionSheetDelegate --------------------
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0:
//            _scannerController.scannerType = IDCardScanner;
            [self presentViewController:_scannerController animated:YES completion:nil];
//            [_scannerController presentScanner:IDCardScanner imageSource:_imageSource inViewController:self];
            break;
            
        case 1:
//            _scannerController.scannerType = PassportScanner;
            [self presentViewController:_scannerController animated:YES completion:nil];
//            [_scannerController presentScanner:PassportScanner imageSource:_imageSource inViewController:self];
            break;
        default:
            break;
    }
}

@end
