//
//  ScanResult.m
//  OCRDemo
//
//  Created by ltp on 6/22/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import "ScanResult.h"

BOOL isPinyin(NSString *string);

//change the possible wrong character to responding number
NSString* modifyAlphabetToNumber(NSString* originStr){
    NSMutableString *tmpString = [NSMutableString stringWithString:originStr];
    [tmpString setString:[tmpString stringByReplacingOccurrencesOfString:@"S" withString:@"5"]];
    [tmpString setString:[tmpString stringByReplacingOccurrencesOfString:@"O" withString:@"0"]];
    [tmpString setString:[tmpString stringByReplacingOccurrencesOfString:@"Z" withString:@"2"]];
    [tmpString setString:[tmpString stringByReplacingOccurrencesOfString:@"U" withString:@"0"]];
    [tmpString setString:[tmpString stringByReplacingOccurrencesOfString:@"D" withString:@"0"]];
    [tmpString setString:[tmpString stringByReplacingOccurrencesOfString:@"I" withString:@"1"]];
    [tmpString setString:[tmpString stringByReplacingOccurrencesOfString:@"B" withString:@"8"]];
    return [NSString stringWithString:tmpString];
}

//change the possible wrong character to responding alphabet
NSString* modifyNumberToAlphabet(NSString* originStr){
    NSMutableString *tmpString = [NSMutableString stringWithString:originStr];
    [tmpString setString:[tmpString stringByReplacingOccurrencesOfString:@"5" withString:@"S"]];
    [tmpString setString:[tmpString stringByReplacingOccurrencesOfString:@"0" withString:@"O"]];
    [tmpString setString:[tmpString stringByReplacingOccurrencesOfString:@"2" withString:@"Z"]];
    [tmpString setString:[tmpString stringByReplacingOccurrencesOfString:@"1" withString:@"I"]];
    [tmpString setString:[tmpString stringByReplacingOccurrencesOfString:@"8" withString:@"B"]];
    return [NSString stringWithString:tmpString];
}

CGRect getRect(NSArray<LetterPosition*> *array, int start, int length, float widthScale, float heightScale){
    if ([array count] < start + length) {
        return CGRectZero;
    }
    CGFloat upper = MAXFLOAT;
    CGFloat bottom = 0;
    for (int i = 0; i < length; i++) {
        if (array[start + i].y < upper) {
            upper = array[start + i].y;
        }
        if (array[start + i].toY > bottom) {
            bottom = array[start + i].toY;
        }
    }
    return CGRectMake(array[start].x * widthScale, upper * heightScale, (array[start + length - 1].toX - array[start].x) * widthScale, (bottom - upper) * heightScale);
}

@implementation ScanResult

- (instancetype)initWithScanResult:(NSString *)scanResult{
    if (self = [super init]) {
        
    }
    return self;
}

@end

@implementation LetterPosition

@end

/**
 **     IDCardScanResult
 **/
@implementation IDCardScanResult

- (instancetype)initWithScanResult:(NSString *)scanResult{
    if (self = [super initWithScanResult:scanResult]) {
        _cardID = scanResult;
    }
    return self;
}

- (void)cropImage:(UIImage *)image inRect:(CGRect)rect withPositions:(NSArray<LetterPosition *> *)pos{
    if (!pos || [pos count] == 0) {
        return;
    }
    //105/330 = 0.318 (105:length of "公民身份号码"   330:length of id card)
    //55/208 = 0.264 (55:height of rect in which the id number possibly exists   208:height of id card)
    CGSize possibleSize = CGSizeMake(rect.size.width - rect.size.width * 0.318, rect.size.height * 0.264);
    CGRect croppedRect  = CGRectMake(rect.origin.x + rect.size.width - possibleSize.width, rect.origin.y + rect.size.height - possibleSize.height, possibleSize.width, possibleSize.height);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], croppedRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);

    CGFloat widthUnit = croppedRect.size.width / 407;
    CGFloat heightUnit = croppedRect.size.height / 100;
    CGRect idRect = getRect(pos, 0, 18, widthUnit, heightUnit);
//    CGRect idRect = CGRectMake(pos[0].x * widthUnit,
//                               pos[0].y * heightUnit,
//                               (pos[pos.count-1].toX - pos[0].x) * widthUnit,
//                               (MAX(pos[0].toY, pos[pos.count - 1].toY) - MIN(pos[0].y, pos[pos.count - 1].y)) * heightUnit
//                               );
    imageRef = CGImageCreateWithImageInRect([croppedImage CGImage], idRect);
    _idImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
}

@end

/**
 **     PassportScanResult
 **/
@implementation PassportScanResult{
    int _familyNameIndex;
    int _familyNameLength;
    int _givenNameIndex;
    int _givenNameLength;
}

- (instancetype)initWithScanResult:(NSString *)scanResult{
    if (self = [super initWithScanResult:scanResult]) {
        if (scanResult && scanResult.length == 88) {
            [self processPassportScanResult:scanResult];
        }
    }
    return self;
}

//Extract data from passport bottom string.
//For more details, please refer to https://en.wikipedia.org/wiki/Machine-readable_passport
- (void)processPassportScanResult:(NSString *)result{
    if (result.length < 88 || [[result substringToIndex:1] isEqual: @"<"]) {
        _gotLegalData = false;
        return;
    }
    NSString *firstLine = [result substringToIndex:44];
    NSString *secondLine = [result substringFromIndex:44];
    
    //process the first line, from which extracted FAMILY NAME, GIVEN NAME, COUNTRY
    //if the nationality is not china mainland, return false
    if (![[firstLine substringWithRange:NSMakeRange(2, 3)] isEqualToString:@"CHN"]) {
        _gotLegalData = false;
        return;
    }
    _nation = @"中国";
    NSArray<NSString*> *splitedStrings = [firstLine  componentsSeparatedByString:@"<<"];
    if (!splitedStrings || [splitedStrings count] < 2) {
        return;
    }
    if (splitedStrings[0].length < 5) {
        return;
    }
    _familyName = modifyNumberToAlphabet([splitedStrings[0] substringFromIndex:5]);
    _givenName = modifyNumberToAlphabet(splitedStrings[1]);
    
    if (!isPinyin(_familyName) || !isPinyin(_givenName)) {
        _gotLegalData = false;
        return;
    }
    _familyNameIndex = 5;
    _familyNameLength = (int)_familyName.length;
    _givenNameIndex = (int)5 + _familyNameLength + 2;
    _givenNameLength = (int)_givenName.length;
    
    //process the second line, from which extracted GENDER, BIRTHDAY, PASSPORT ID
    NSString *idString = [secondLine substringToIndex:9];
    _passportID = [modifyNumberToAlphabet([idString substringToIndex:1]) stringByAppendingString:modifyAlphabetToNumber([idString substringWithRange:NSMakeRange(1, 8)])];
    
    NSString *birthdayString = [secondLine substringWithRange:NSMakeRange(13, 6)];
    int year = [[birthdayString substringToIndex:2] intValue];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    birthdayString = (year > 30)?[@"19" stringByAppendingString:birthdayString]:[@"20" stringByAppendingString:birthdayString];
    _birthday = [dateFormatter dateFromString:birthdayString];
    
    _gender = ([secondLine characterAtIndex:20] == 'M')?1:0;
    _gotLegalData = true;
}

//In the OCR processing, the program split the image into 700(width)*131(height)
//so the positions returned by the program is based on this prequisite
- (void)cropImage:(UIImage*)image inRect:(CGRect)rect withPositions:(NSArray<LetterPosition*>*)pos{
    //0.158 = 1/6.33, 6.33 is the ratio of passport id string image's width to height
    CGRect croppedRect  = CGRectMake(rect.origin.x, rect.origin.y + rect.size.height - rect.size.width * 0.158, rect.size.width, rect.size.width * 0.158);
    CGFloat widthUnit = croppedRect.size.width / 700;
    CGFloat heightUnit = croppedRect.size.height / 131;
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], croppedRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    //TODO: the height should be the max among all the family name's letter
//    CGRect familyNameRect = CGRectMake((pos[_familyNameIndex].x - 4) * widthUnit, pos[_familyNameIndex].y * heightUnit,
//                                       (pos[_familyNameIndex + _familyNameLength - 1].toX - pos[_familyNameIndex].x + 4) * widthUnit ,
//                                       (MAX(pos[_familyNameIndex + _familyNameLength - 1].toY, pos[_familyNameIndex].toY) - MIN(pos[_familyNameIndex + _familyNameLength - 1].y, pos[_familyNameIndex].y)) * heightUnit
//                                       );
    CGRect familyNameRect = getRect(pos, _familyNameIndex, _familyNameLength, widthUnit, heightUnit);
    imageRef = CGImageCreateWithImageInRect(croppedImage.CGImage, familyNameRect);
    _familyNameImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    //TODO: the height should be the max among all the given name's letter
//    CGRect givenNameRect = CGRectMake((pos[_givenNameIndex].x - 4) * widthUnit, pos[_givenNameIndex].y * heightUnit,
//                                      (pos[_givenNameIndex + _givenNameLength - 1].toX - pos[_givenNameIndex].x + 4) * widthUnit ,
//                                      (MAX(pos[_givenNameIndex + _givenNameLength - 1].toY, pos[_givenNameIndex].toY) - MIN(pos[_givenNameIndex + _givenNameLength - 1].y, pos[_givenNameIndex].y)) * heightUnit
//                                      );
    CGRect givenNameRect = getRect(pos, _givenNameIndex, _givenNameLength, widthUnit, heightUnit);
    imageRef = CGImageCreateWithImageInRect(croppedImage.CGImage, givenNameRect);
    _givenNameImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    //TODO: the height should be the max among all the id string's letter
    NSInteger idImageY = INT_MAX;
    for (int i = 44; i < 52; i++) {
        if (pos[i].y < idImageY) {
            idImageY = pos[i].y;
        }
    }
//    CGRect idRect = CGRectMake((pos[44].x - 4) * widthUnit, idImageY * heightUnit,
//                               (pos[52].toX - pos[44].x + 4) * widthUnit,
//                               (MAX(pos[44].toY, pos[52].toY) - MIN(pos[44].y, pos[52].y)) * heightUnit
//                               );
    CGRect idRect = getRect(pos, 44, 9, widthUnit, heightUnit);
    imageRef = CGImageCreateWithImageInRect(croppedImage.CGImage, idRect);
    _idImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    //    int i=0;
    //    for (LetterPosition *p in pos) {i++;
    //        CGRect givenNameRect = CGRectMake(p.x * widthUnit, p.y * heightUnit, (p.toX - p.x) * widthUnit, (p.toY - p.y) * heightUnit);
    //        imageRef = CGImageCreateWithImageInRect(croppedImage.CGImage, givenNameRect);
    //        UIImage *tmpImage = [UIImage imageWithCGImage:imageRef];
    //        CGImageRelease(imageRef);
    //    }
}

@end

BOOL isPinyin(NSString *string){
    
    NSArray *pinyin = @[@"A", @"AI", @"AN", @"ANG", @"AO", @"BA", @"BAI", @"BAN",
                        @"BANG", @"BAO", @"BEI", @"BEN", @"BENG", @"BI", @"BIAN", @"BIAO", @"BIE",
                        @"BIN", @"BING", @"BO", @"BU", @"CA", @"CAI", @"CAN", @"CANG", @"CAO", @"CE",
                        @"CEN", @"CENG", @"CHA", @"CHAI", @"CHAN", @"CHANG", @"CHAO", @"CHE",
                        @"CHEN", @"CHENG", @"CHI", @"CHONG", @"CHOU", @"CHU", @"CHUA", @"CHUAI",
                        @"CHUAN", @"CHUANG", @"CHUI", @"CHUN", @"CHUO", @"CI", @"CONG", @"COU",
                        @"CU", @"CUAN", @"CUI", @"CUN", @"CUO", @"DA", @"DAI", @"DAN", @"DANG",
                        @"DAO", @"DE", @"DEN", @"DEI", @"DENG", @"DI", @"DIA", @"DIAN", @"DIAO",
                        @"DIE", @"DING", @"DIU", @"DONG", @"DOU", @"DU", @"DUAN", @"DUI", @"DUN",
                        @"DUO", @"E", @"EI", @"EN", @"ENG", @"ER", @"FA", @"FAN", @"FANG", @"FEI",
                        @"FEN", @"FENG", @"FO", @"FOU", @"FU", @"GA", @"GAI", @"GAN", @"GANG", @"GAO",
                        @"GE", @"GEI", @"GEN", @"GENG", @"GONG", @"GOU", @"GU", @"GUA", @"GUAI",
                        @"GUAN", @"GUANG", @"GUI", @"GUN", @"GUO", @"HA", @"HAI", @"HAN", @"HANG",
                        @"HAO", @"HE", @"HEI", @"HEN", @"HENG", @"HONG", @"HOU", @"HU", @"HUA",
                        @"HUAI", @"HUAN", @"HUANG", @"HUI", @"HUN", @"HUO", @"JI", @"JIA", @"JIAN",
                        @"JIANG", @"JIAO", @"JIE", @"JIN", @"JING", @"JIONG", @"JIU", @"JU", @"JUAN",
                        @"JUE", @"JUN", @"KA", @"KAI", @"KAN", @"KANG", @"KAO", @"KE", @"KEN",
                        @"KENG", @"KONG", @"KOU", @"KU", @"KUA", @"KUAI", @"KUAN", @"KUANG", @"KUI",
                        @"KUN", @"KUO", @"LA", @"LAI", @"LAN", @"LANG", @"LAO", @"LE", @"LEI",
                        @"LENG", @"LI", @"LIAN", @"LIANG", @"LIAO", @"LIE", @"LIN", @"LING",
                        @"LIU", @"LONG", @"LOU", @"LU", @"LV", @"LUAN", @"LUE", @"LVE", @"LUN",
                        @"LUO", @"MA", @"MAI", @"MAN", @"MANG", @"MAO", @"ME", @"MEI", @"MEN",
                        @"MENG", @"MI", @"MIAN", @"MIAO", @"MIE", @"MIN", @"MING", @"MIU", @"MO",
                        @"MOU", @"MU", @"NA", @"NAI", @"NAN", @"NANG", @"NAO", @"NE", @"NEI", @"NEN",
                        @"NENG", @"NI", @"NIAN", @"NIANG", @"NIAO", @"NIE", @"NIN", @"NING", @"NIU",
                        @"NONG", @"NOU", @"NU", @"NV", @"NUAN", @"NVE", @"NUE", @"NUO", @"NUN", @"O",
                        @"OU", @"PA", @"PAI", @"PAN", @"PANG", @"PAO", @"PEI", @"PEN", @"PENG", @"PI",
                        @"PIAN", @"PIAO", @"PIE", @"PIN", @"PING", @"PO", @"POU", @"PU", @"QI",
                        @"QIA", @"QIAN", @"QIANG", @"QIAO", @"QIE", @"QIN", @"QING", @"QIONG",
                        @"QIU", @"QU", @"QUAN", @"QUE", @"QUN", @"RAN", @"RANG", @"RAO", @"RE",
                        @"REN", @"RENG", @"RI", @"RONG", @"ROU", @"RU", @"RUAN", @"RUI", @"RUN",
                        @"RUO", @"SA", @"SAI", @"SAN", @"SANG", @"SAO", @"SE", @"SEN", @"SENG",
                        @"SHA", @"SHAI", @"SHAN", @"SHANG", @"SHAO", @"SHE", @"SHEI", @"SHEN",
                        @"SHENG", @"SHI", @"SHOU", @"SHU", @"SHUA", @"SHUAI", @"SHUAN", @"SHUANG",
                        @"SHUI", @"SHUN", @"SHUO", @"SI", @"SONG", @"SOU", @"SU", @"SUAN", @"SUI",
                        @"SUN", @"SUO", @"TA", @"TAI", @"TAN", @"TANG", @"TAO", @"TE", @"TENG", @"TI",
                        @"TIAN", @"TIAO", @"TIE", @"TING", @"TONG", @"TOU", @"TU", @"TUAN", @"TUI",
                        @"TUN", @"TUO", @"WA", @"WAI", @"WAN", @"WANG", @"WEI", @"WEN", @"WENG",
                        @"WO", @"WU", @"XI", @"XIA", @"XIAN", @"XIANG", @"XIAO", @"XIE", @"XIN",
                        @"XING", @"XIONG", @"XIU", @"XU", @"XUAN", @"XUE", @"XUN", @"YA", @"YAN",
                        @"YANG", @"YAO", @"YE", @"YI", @"YIN", @"YING", @"YO", @"YONG", @"YOU", @"YU",
                        @"YUAN", @"YUE", @"YUN", @"ZA", @"ZAI", @"ZAN", @"ZANG", @"ZAO", @"ZE",
                        @"ZEI", @"ZEN", @"ZENG", @"ZHA", @"ZHAI", @"ZHAN", @"ZHANG", @"ZHAO", @"ZHE",
                        @"ZHEI", @"ZHEN", @"ZHENG", @"ZHI", @"ZHONG", @"ZHOU", @"ZHU", @"ZHUA",
                        @"ZHUAI", @"ZHUAN", @"ZHUANG", @"ZHUI", @"ZHUN", @"ZHUO", @"ZI", @"ZONG",
                        @"ZOU", @"ZU", @"ZUAN", @"ZUI", @"ZUN", @"ZUO"];
    
    for (NSString *str in pinyin) {
        if (str.length > string.length) {
            continue;
        }
        if ([[string substringToIndex:str.length] isEqualToString:str]) {
            if (string.length == str.length) {
                return true;
            }
            else if (isPinyin([string substringFromIndex:str.length])){
                return true;
            }
        }
    }
    return false;
}