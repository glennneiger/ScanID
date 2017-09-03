//
//  CameraOverlay.h
//  OCRDemo
//
//  Created by ltp on 6/12/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum {
    CameraOverlayTypePassport,
    CameraOverlayTypeIDCard
} CameraOverlayType ;
typedef void(^doBlock) (void);
typedef void(^doSenderBlock) (id sender);

@interface CameraOverlay : UIView

@property (copy, nonatomic) doBlock dismissImagePicker;
@property (copy, nonatomic) doSenderBlock tapFlashLight;
@property (copy, nonatomic) doBlock tapTip;
@property (copy, nonatomic) doBlock doOCR;
@property (copy, nonatomic) doBlock tapIDCardBtn;
@property (copy, nonatomic) doBlock tapPassportBtn;
@property (copy, nonatomic) doBlock doChoosePicture;  //pick photos from album for OCR
@property (copy, nonatomic) doBlock doTakingPicture;    //return from image mode to real-time mode, i.e., taking video.

@property (assign, nonatomic) CGRect idStringRect;
@property (assign, nonatomic) CGRect passportRect;

- (void)cancelPhotoScanningMode;
@end
