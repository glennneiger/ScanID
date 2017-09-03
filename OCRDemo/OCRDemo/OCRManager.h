//
//  OCRManager.h
//  OCRDemo
//
//  Created by ltp on 5/26/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OCRManager : NSObject

-(NSString *)scanPic;

- (UIImage *)getGreyScaleImage:(UIImage *)image;

- (UIImage *)getBlackImage:(UIImage *)image;

- (UIImage *)getEdge:(UIImage *)image;

@end
