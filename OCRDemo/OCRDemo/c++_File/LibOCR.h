//
//  LibOCR.h
//  OCRDemo
//
//  Created by ltp on 7/12/16.
//  Copyright © 2016 ltp. All rights reserved.
//

#ifndef LibOCR_h
#define LibOCR_h
#ifdef __cplusplus
extern "C" {
#endif

    char* libOCRScanIDCard(int8_t *arr, int hw, int hh, int x, int y, int w, int h);
    char* libOCRScanPassport(int8_t *arr,int hw,int hh,int x,int y,int w,int h);
    
#ifdef __cplusplus
}
#endif
#endif /* LibOCR_h */
