//
//  OCRValidationView.m
//  OCRDemo
//
//  Created by ltp on 6/23/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "OCRValidationView.h"

#define kButtonWidth 240.0
#define kButtonHeight 44.0
#define kScreenWidth [UIScreen mainScreen].bounds.size.width

@implementation OCRValidationView{
    UIView *_validationContainer;
    PassportScanResult *_passportModel;
    UIButton *_okButton;
    UIImageView *_croppedImageView;
    UILabel *_tipLabel;
}

- (instancetype)initWithPassportScanResult:(PassportScanResult *)passportModel validRects:(NSArray*)rects{
    if (self = [super init]) {
        [self initView];
        _passportModel = passportModel;
    }
    return self;
}

- (void)initView{
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(12, 33, 18, 18)];
    [backButton setTitle:@"back" forState:UIControlStateNormal];
    [self addSubview:backButton];
    
    _tipLabel = [[UILabel alloc] init];
    [_tipLabel setText:@"若识别错误可点击输入框修改"];
    [_tipLabel setFont:[UIFont systemFontOfSize:13.0]];
    _tipLabel.backgroundColor = [UIColor clearColor];
    [_tipLabel setTextColor:[UIColor whiteColor]];
    _tipLabel.numberOfLines = 1;
//    CGSize tipLabelSize = [_tipLabel.text sizeWithAttributes:@{NSFontAttributeName:_tipLabel.font}];
//    _okButton = [UIButton alloc] initWithFrame:CGRectMake((kScreenWidth - kButtonWidth) / 2, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>);
}

@end
