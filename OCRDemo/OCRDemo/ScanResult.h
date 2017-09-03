//
//  ScanResult.h
//  OCRDemo
//
//  Created by ltp on 6/22/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//the basic class of all scan result
@interface ScanResult : NSObject

- (instancetype)initWithScanResult:(NSString *)scanResult;

@end

@interface LetterPosition : NSObject

@property (assign, nonatomic) NSInteger x;
@property (assign, nonatomic) NSInteger y;
@property (assign, nonatomic) NSInteger toX;    //right point x
@property (assign, nonatomic) NSInteger toY;    //bottom point y

@end

@interface PassportScanResult : ScanResult

@property (strong, nonatomic) NSString *givenName;  //名
@property (strong, nonatomic) NSString *familyName; //姓
@property (strong, nonatomic) NSString *passportID;
@property (strong, nonatomic) NSString *nation;
@property (strong, nonatomic) NSDate *birthday;
@property (assign, nonatomic) NSInteger gender; //0 for female, 1 for male
@property (assign, nonatomic) BOOL gotLegalData;     //judge if information extracted from the init string is legal
@property (strong, nonatomic) UIImage *familyNameImage;
@property (strong, nonatomic) UIImage *givenNameImage;
@property (strong, nonatomic) UIImage *idImage;

- (void)cropImage:(UIImage*)image inRect:(CGRect)rect withPositions:(NSArray<LetterPosition*>*)pos;

@end

@interface IDCardScanResult : ScanResult

@property (strong, nonatomic) NSString *cardID;
@property (strong, nonatomic) UIImage *idImage;

- (void)cropImage:(UIImage*)image inRect:(CGRect)rect withPositions:(NSArray<LetterPosition*>*)pos;

@end