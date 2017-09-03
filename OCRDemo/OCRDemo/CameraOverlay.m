//
//  CameraOverlay.m
//  OCRDemo
//
//  Created by ltp on 6/12/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "CameraOverlay.h"

#define ScreenHeight [[UIScreen mainScreen] bounds].size.height
#define ScreenWidth [[UIScreen mainScreen] bounds].size.width
#define ColorHex(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 green:((c>>8)&0xFF)/255.0 blue:((c)&0xFF)/255.0 alpha:1.0]

#define kDefaultWidth 320.0

void addMask(UIView *containerView, CGRect transparentRect, UIColor *maskColor){
    CGPoint origin = transparentRect.origin;
    CGSize size = transparentRect.size;
    if (origin.y > 0) {
        UIView *upperMask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, origin.y)];
        upperMask.backgroundColor = maskColor;
        [containerView addSubview:upperMask];
    }
    if (origin.x > 0) {
        UIView *leftMask = [[UIView alloc] initWithFrame:CGRectMake(0, origin.y, origin.x, size.height)];
        leftMask.backgroundColor = maskColor;
        [containerView addSubview:leftMask];
    }
    if (origin.x + size.width < ScreenWidth) {
        UIView *rightMask = [[UIView alloc] initWithFrame:CGRectMake(origin.x + size.width, origin.y, ScreenWidth - (origin.x + size.width), size.height)];
        rightMask.backgroundColor = maskColor;
        [containerView addSubview:rightMask];
    }
    if (origin.y + size.height < ScreenHeight) {
        UIView *bottomMask = [[UIView alloc] initWithFrame:CGRectMake(0, origin.y + size.height, ScreenWidth, ScreenHeight - (origin.y + size.height))];
        bottomMask.backgroundColor = maskColor;
        [containerView addSubview: bottomMask];
    }
}

@implementation CameraOverlay{
    CGFloat _width;
    CGFloat _height;
    UIView *_container;
    UIView *_IDCardContainer;
    UIView *_passportContainer;
    UIButton *_passportBtn;
    UIButton *_IDCardBtn;
    UIButton *_backBtn;
    UIButton *_flashBtn;
    UIButton *_photoBtn;
    UIButton *_cancelBtn;
    UIButton *_triggerBtn;
    CAShapeLayer *_triangleLayerA;
    CAShapeLayer *_triangleLayerB;
}

- (instancetype)init{
    if (self = [super init]) {
        _height = (ScreenWidth > ScreenHeight)?ScreenWidth : ScreenHeight;
        _width = (ScreenWidth < ScreenHeight)?ScreenWidth : ScreenHeight;
        [self initView];
    }
    return self;
}

- (void)initView{
    float scaleRatio = ScreenWidth / kDefaultWidth;
    //    self.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.6];
    self.opaque = NO;
    self.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    
    //init mask view
    _container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    _IDCardContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    _passportContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    [self addSubview:_container];

    //passport overlay
    CGRect passportRect = CGRectMake((ScreenWidth - 249 * scaleRatio) / 2, (ScreenHeight - 354 * scaleRatio) / 2, 249 * scaleRatio, 354 * scaleRatio);
    UIView *passportMask = [[UIView alloc] initWithFrame:passportRect];
    UIView *innerOverlay = [[UIView alloc] initWithFrame:CGRectMake(56 * scaleRatio, 0, 193 * scaleRatio, 354 * scaleRatio)];
    innerOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65];
    [passportMask addSubview:innerOverlay];
    UIImageView *barCodeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"barcode"]];
    barCodeView.transform = CGAffineTransformMakeRotation(M_PI/2);
    barCodeView.frame = CGRectMake(0, 0, 56 * scaleRatio, passportMask.frame.size.height);
    [passportMask addSubview:barCodeView];
    [_passportContainer addSubview:passportMask];
    addMask(_passportContainer, passportRect, [[UIColor blackColor] colorWithAlphaComponent:0.85]);
    
    UILabel *tipLabel = [[UILabel alloc] init];
    tipLabel.numberOfLines = 1;
    tipLabel.font = [UIFont systemFontOfSize:13.0];
    tipLabel.textColor = [UIColor whiteColor];
    tipLabel.text = @"请将护照个人资料页底部条码置于上方框内，且证件表面无反光";
    CGSize tipLabelSize = [tipLabel.text sizeWithAttributes:@{NSFontAttributeName:tipLabel.font}];
    tipLabel.transform = CGAffineTransformMakeRotation(M_PI/2);
    tipLabel.frame = CGRectMake(passportRect.origin.x - 13 * scaleRatio - tipLabelSize.height, (ScreenHeight - tipLabelSize.width) / 2, tipLabelSize.height, tipLabelSize.width);
    [_passportContainer addSubview:tipLabel];
    
    UIButton *tipButton = [[UIButton alloc] init];
    [tipButton addTarget:self action:@selector(tip) forControlEvents:UIControlEventTouchUpInside];
    [tipButton setImage:[UIImage imageNamed:@"ico_question"] forState:UIControlStateNormal];
    tipButton.transform = CGAffineTransformMakeRotation(M_PI/2);
    tipButton.frame = CGRectMake(tipLabel.frame.origin.x + tipLabelSize.height / 2 - 33 / 2, tipLabel.frame.origin.y + tipLabelSize.width + 5 * scaleRatio, 33, 33);
    [_passportContainer addSubview:tipButton];
    
    UIBezierPath *linePath = [UIBezierPath bezierPath];
    //up left
    [linePath moveToPoint:CGPointMake(passportRect.origin.x, passportRect.origin.y + 15 * scaleRatio)];
    [linePath addLineToPoint:passportRect.origin];
    [linePath addLineToPoint:CGPointMake(passportRect.origin.x + 15 * scaleRatio, passportRect.origin.y)];
    //up right
    [linePath moveToPoint:CGPointMake(passportRect.origin.x + passportRect.size.width - 15 * scaleRatio, passportRect.origin.y)];
    [linePath addLineToPoint:CGPointMake(passportRect.origin.x + passportRect.size.width, passportRect.origin.y)];
    [linePath addLineToPoint:CGPointMake(passportRect.origin.x + passportRect.size.width, passportRect.origin.y + 15 * scaleRatio)];
    //right bottom
    [linePath moveToPoint:CGPointMake(passportRect.origin.x + passportRect.size.width, passportRect.origin.y + passportRect.size.height - 15 * scaleRatio)];
    [linePath addLineToPoint:CGPointMake(passportRect.origin.x + passportRect.size.width, passportRect.origin.y + passportRect.size.height)];
    [linePath addLineToPoint:CGPointMake(passportRect.origin.x + passportRect.size.width - 15 * scaleRatio, passportRect.origin.y + passportRect.size.height)];
    //left bottom
    [linePath moveToPoint:CGPointMake(passportRect.origin.x, passportRect.origin.y + passportRect.size.height - 15 * scaleRatio)];
    [linePath addLineToPoint:CGPointMake(passportRect.origin.x, passportRect.origin.y + passportRect.size.height)];
    [linePath addLineToPoint:CGPointMake(passportRect.origin.x + 15 * scaleRatio, passportRect.origin.y + passportRect.size.height)];
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [linePath CGPath];
    shapeLayer.strokeColor = [ColorHex(0x6AEE00) CGColor];
    shapeLayer.lineWidth = 2.0f;
    shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    
    [_passportContainer.layer addSublayer:shapeLayer];
    

    //ID card overlay
    CGRect cardRect = CGRectMake((ScreenWidth - 232 * scaleRatio) / 2, (ScreenHeight - 365 * scaleRatio) / 2, 232 * scaleRatio, 365 * scaleRatio);
    addMask(_IDCardContainer, cardRect, [[UIColor blackColor] colorWithAlphaComponent:0.85]);
    UILabel *idTipLabel = [[UILabel alloc] init];
    idTipLabel.numberOfLines = 1;
    idTipLabel.font = [UIFont systemFontOfSize:14.0];
    idTipLabel.textColor = [UIColor whiteColor];
    idTipLabel.text = @"请将身份证置于框内并尝试对齐边缘";
    CGSize idTipLabelSize = [idTipLabel.text sizeWithAttributes:@{NSFontAttributeName:idTipLabel.font}];
    idTipLabel.transform = CGAffineTransformMakeRotation(M_PI/2);
    idTipLabel.frame = CGRectMake(cardRect.origin.x - 12 * scaleRatio - idTipLabelSize.height, (ScreenHeight - idTipLabelSize.width) / 2, idTipLabelSize.height, idTipLabelSize.width);
    [_IDCardContainer addSubview:idTipLabel];
    
    UIButton *idTipButton = [[UIButton alloc] init];
    [idTipButton addTarget:self action:@selector(tip) forControlEvents:UIControlEventTouchUpInside];
    [idTipButton setImage:[UIImage imageNamed:@"ico_question"] forState:UIControlStateNormal];
    idTipButton.transform = CGAffineTransformMakeRotation(M_PI/2);
    idTipButton.frame = CGRectMake(idTipLabel.frame.origin.x + idTipLabelSize.height / 2 - 33 / 2, idTipLabel.frame.origin.y + idTipLabelSize.width + 5 * scaleRatio, 33, 33);
    [_IDCardContainer addSubview:idTipButton];
    
//    UILabel *IDCardPhoto = [[UILabel alloc] init];
//    IDCardPhoto.text = @"照片";
//    IDCardPhoto.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1f];
//    IDCardPhoto.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.3f];
//    IDCardPhoto.font = [UIFont systemFontOfSize:18.0f];
//    IDCardPhoto.transform = CGAffineTransformMakeRotation(M_PI/2);
//    IDCardPhoto.frame = CGRectMake(cardRect.origin.x + cardRect.size.width - (150 + 29) * scaleRatio, cardRect.origin.y + cardRect.size.height - (111 + 27) * scaleRatio, 150 * scaleRatio, 111 * scaleRatio);
//    IDCardPhoto.textAlignment = NSTextAlignmentCenter;
//    [_IDCardContainer addSubview:IDCardPhoto];
    
    UIBezierPath *linePathB = [UIBezierPath bezierPath];
    //up left
    [linePathB moveToPoint:CGPointMake(cardRect.origin.x, cardRect.origin.y + 15 * scaleRatio)];
    [linePathB addLineToPoint:cardRect.origin];
    [linePathB addLineToPoint:CGPointMake(cardRect.origin.x + 15 * scaleRatio, cardRect.origin.y)];
    //up right
    [linePathB moveToPoint:CGPointMake(cardRect.origin.x + cardRect.size.width - 15 * scaleRatio, cardRect.origin.y)];
    [linePathB addLineToPoint:CGPointMake(cardRect.origin.x + cardRect.size.width, cardRect.origin.y)];
    [linePathB addLineToPoint:CGPointMake(cardRect.origin.x + cardRect.size.width, cardRect.origin.y + 15 * scaleRatio)];
    //right bottom
    [linePathB moveToPoint:CGPointMake(cardRect.origin.x + cardRect.size.width, cardRect.origin.y + cardRect.size.height - 15 * scaleRatio)];
    [linePathB addLineToPoint:CGPointMake(cardRect.origin.x + cardRect.size.width, cardRect.origin.y + cardRect.size.height)];
    [linePathB addLineToPoint:CGPointMake(cardRect.origin.x + cardRect.size.width - 15 * scaleRatio, cardRect.origin.y + cardRect.size.height)];
    //left bottom
    [linePathB moveToPoint:CGPointMake(cardRect.origin.x, cardRect.origin.y + cardRect.size.height - 15 * scaleRatio)];
    [linePathB addLineToPoint:CGPointMake(cardRect.origin.x, cardRect.origin.y + cardRect.size.height)];
    [linePathB addLineToPoint:CGPointMake(cardRect.origin.x + 15 * scaleRatio, cardRect.origin.y + cardRect.size.height)];
    CAShapeLayer *shapeLayerB = [CAShapeLayer layer];
    shapeLayerB.path = [linePathB CGPath];
    shapeLayerB.strokeColor = [ColorHex(0x6AEE00) CGColor];
    shapeLayerB.lineWidth = 2.0f;
    shapeLayerB.fillColor = [[UIColor clearColor] CGColor];
    
    [_IDCardContainer.layer addSublayer:shapeLayerB];
    
    _backBtn = [[UIButton alloc] init];
    [_backBtn setImage:[UIImage imageNamed:@"back_arrow"] forState:UIControlStateNormal];
    [_backBtn setBackgroundColor:[UIColor clearColor]];
    [_backBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    _backBtn.transform = CGAffineTransformMakeRotation(M_PI/2);
    _backBtn.frame = CGRectMake(ScreenWidth - 33 - 5, 10, 33, 33);
    [self addSubview:_backBtn];
    _flashBtn = [[UIButton alloc] init];
    [_flashBtn setBackgroundColor:[UIColor clearColor]];
    [_flashBtn setImage:[UIImage imageNamed:@"light_off"] forState:UIControlStateNormal];
    [_flashBtn addTarget:self action:@selector(flashLight:) forControlEvents:UIControlEventTouchUpInside];
    _flashBtn.transform = CGAffineTransformMakeRotation(M_PI/2);
    _flashBtn.frame = CGRectMake(ScreenWidth - 33 - 5, ScreenHeight - 33 - 10, 33, 33);
    [self addSubview:_flashBtn];
    _photoBtn = [[UIButton alloc] init];
    [_photoBtn addTarget:self action:@selector(enterPhotoScanningMode) forControlEvents:UIControlEventTouchUpInside];
    [_photoBtn setImage:[UIImage imageNamed:@"ico_photo"] forState:UIControlStateNormal];
    _photoBtn.transform = CGAffineTransformMakeRotation(M_PI/2);
    _photoBtn.frame = CGRectMake(_flashBtn.frame.origin.x, _flashBtn.frame.origin.y - 10 - 33, 33, 33);
    [self addSubview:_photoBtn];
    
    _IDCardBtn = [[UIButton alloc] init];
    [_IDCardBtn setTitle:@"身份证" forState:UIControlStateNormal];
    [_IDCardBtn setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3] forState:UIControlStateNormal];
    _IDCardBtn.transform = CGAffineTransformMakeRotation(M_PI/2);
    [_IDCardBtn addTarget:self action:@selector(switchToIDCard:) forControlEvents:UIControlEventAllTouchEvents];
    _IDCardBtn.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    _IDCardBtn.frame = CGRectMake(_backBtn.frame.origin.x + _backBtn.frame.size.width / 2, cardRect.origin.y + cardRect.size.height/2 - 75 - 20 , 15, 75 * scaleRatio);
    [self addSubview:_IDCardBtn];
    //add little triangle
    UIBezierPath *trianglePathA = [UIBezierPath bezierPath];
    [trianglePathA moveToPoint:CGPointMake(_IDCardBtn.frame.origin.x - 4 * scaleRatio, _IDCardBtn.frame.origin.y + _IDCardBtn.frame.size.height / 2 - 5 * scaleRatio)];
    [trianglePathA addLineToPoint:CGPointMake(_IDCardBtn.frame.origin.x - 4 * scaleRatio, _IDCardBtn.frame.origin.y + _IDCardBtn.frame.size.height / 2 + 5 * scaleRatio)];
    [trianglePathA addLineToPoint:CGPointMake(_IDCardBtn.frame.origin.x - (4 + 5) * scaleRatio, _IDCardBtn.frame.origin.y + _IDCardBtn.frame.size.height / 2)];
    _triangleLayerA = [CAShapeLayer layer];
    _triangleLayerA.path = [trianglePathA CGPath];
    _triangleLayerA.strokeColor = [ColorHex(0x099FDE) CGColor];
    _triangleLayerA.fillColor = [ColorHex(0x099FDE) CGColor];
    [_IDCardContainer.layer addSublayer:_triangleLayerA];
    
    _passportBtn = [[UIButton alloc] init];
    [_passportBtn setTitle:@"护照（中国大陆）" forState:UIControlStateNormal];
    [_passportBtn setTitleColor:ColorHex(0x099FDE) forState:UIControlStateNormal];
    _passportBtn.transform = CGAffineTransformMakeRotation(M_PI/2);
    [_passportBtn addTarget:self action:@selector(switchToPassport:) forControlEvents:UIControlEventAllTouchEvents];
    _passportBtn.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    _passportBtn.frame = CGRectMake(_backBtn.frame.origin.x + _backBtn.frame.size.width / 2, cardRect.origin.y + cardRect.size.height/2 - 20 , 15, 140 * scaleRatio);
    [self addSubview:_passportBtn];
    //add little triangle
    UIBezierPath *trianglePathB = [UIBezierPath bezierPath];
    [trianglePathB moveToPoint:CGPointMake(_passportBtn.frame.origin.x - 4 * scaleRatio, _passportBtn.frame.origin.y + _passportBtn.frame.size.height / 2 - 5 * scaleRatio)];
    [trianglePathB addLineToPoint:CGPointMake(_passportBtn.frame.origin.x - 4 * scaleRatio, _passportBtn.frame.origin.y + _passportBtn.frame.size.height / 2 + 5 * scaleRatio)];
    [trianglePathB addLineToPoint:CGPointMake(_passportBtn.frame.origin.x - (4 + 5) * scaleRatio, _passportBtn.frame.origin.y + _passportBtn.frame.size.height / 2)];
    _triangleLayerB = [CAShapeLayer layer];
    _triangleLayerB.path = [trianglePathB CGPath];
    _triangleLayerB.strokeColor = [ColorHex(0x099FDE) CGColor];
    _triangleLayerB.fillColor = [ColorHex(0x099FDE) CGColor];
    [_passportContainer.layer addSublayer:_triangleLayerB];
    
    [_container addSubview:_passportContainer];
    
    _cancelBtn = [[UIButton alloc] init];
    _cancelBtn.transform = CGAffineTransformMakeRotation(M_PI/2);
    _cancelBtn.frame = CGRectMake(_backBtn.frame.origin.x + 5 * scaleRatio, _backBtn.frame.origin.y + 5 * scaleRatio, 18 * scaleRatio, 40 * scaleRatio);
    [_cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    _cancelBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [_cancelBtn addTarget:self action:@selector(cancelPhotoScanningMode) forControlEvents:UIControlEventTouchUpInside];
    _cancelBtn.hidden = true;
    [self addSubview:_cancelBtn];
    
    _triggerBtn = [[UIButton alloc] init];
    _triggerBtn.transform = CGAffineTransformMakeRotation(M_PI/2);
    [_triggerBtn setTitle:@"开始识别" forState:UIControlStateNormal];
    _triggerBtn.layer.cornerRadius = 8.0f;
    _triggerBtn.layer.borderWidth = 1.0f;
    _triggerBtn.layer.borderColor = [ColorHex(0xFF9A14) CGColor];
    [_triggerBtn setTitleColor:ColorHex(0xFF9A14) forState:UIControlStateNormal];
    _triggerBtn.frame = CGRectMake(_photoBtn.frame.origin.x, _photoBtn.frame.origin.y - 10 * scaleRatio, 30 * scaleRatio, 80 * scaleRatio);
    _triggerBtn.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    _triggerBtn.hidden = true;
    [_triggerBtn addTarget:self action:@selector(OCR) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_triggerBtn];
    
}

- (void)switchToPassport:(id)sender{
    [_IDCardContainer removeFromSuperview];
    [_container addSubview:_passportContainer];
    [((UIButton *)sender) setTitleColor:ColorHex(0x099FDE) forState:UIControlStateNormal];
    [_IDCardBtn setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3] forState:UIControlStateNormal];
    if (_tapPassportBtn) {
        _tapPassportBtn();
    }
}

- (void)switchToIDCard:(id)sender{
    [_passportContainer removeFromSuperview];
    [_container addSubview:_IDCardContainer];
    [((UIButton *)sender) setTitleColor:ColorHex(0x099FDE) forState:UIControlStateNormal];
    [_passportBtn setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3] forState:UIControlStateNormal];
    if (_tapIDCardBtn) {
        _tapIDCardBtn();
    }
}

- (void)cancelPhotoScanningMode{
    _triggerBtn.hidden = YES;
    _cancelBtn.hidden = YES;
    _IDCardBtn.hidden = NO;
    _passportBtn.hidden = NO;
    _backBtn.hidden = NO;
    _flashBtn.hidden = NO;
    _photoBtn.hidden = NO;
    _triangleLayerA.hidden = NO;
    _triangleLayerB.hidden = NO;
    if (_doTakingPicture) {
        _doTakingPicture();
    }
}

- (void)enterPhotoScanningMode{
    _triggerBtn.hidden = NO;
    _cancelBtn.hidden = NO;
    _IDCardBtn.hidden = YES;
    _passportBtn.hidden = YES;
    _backBtn.hidden = YES;
    _flashBtn.hidden = YES;
    _photoBtn.hidden = YES;
    _triangleLayerA.hidden = YES;
    _triangleLayerB.hidden = YES;
    if (_doChoosePicture) {
        _doChoosePicture();
    }
}

- (void)back{
    if (_dismissImagePicker) {
        _dismissImagePicker();
    }
}

- (void)flashLight:(id)sender{
    if (_tapFlashLight) {
        _tapFlashLight(sender);
    }
}

- (void)tip{
    if (_tapTip) {
        _tapTip();
    }
}

- (void)OCR{
    if (_doOCR) {
        _doOCR();
    }
}

@end
