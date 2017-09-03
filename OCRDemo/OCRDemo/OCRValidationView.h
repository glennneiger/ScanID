//
//  OCRValidationView.h
//  OCRDemo
//
//  Created by ltp on 6/23/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScanResult.h"

@interface OCRValidationView : UIView

- (instancetype)initWithPassportScanResult:(PassportScanResult *)passportModel validRects:(NSArray*)rects;

- (void)validFamilyNameInRect:(CGRect)rect;

- (void)validGivenNameInRect:(CGRect)rect;

- (void)validIDInRect:(CGRect)rect;

@end
