//
//  CaptchaSlider.m
//  CaptchaDemo
//
//  Created by alex on 20/04/2017.
//  Licence: WTFPL
//

#import <UIKit/UIKit.h>

@class CaptchaSlider;

@protocol CaptchaSliderDelegate <NSObject>

@optional

- (void)sliderValueChanging:(CaptchaSlider *)slider;

- (void)sliderEndValueChanged:(CaptchaSlider *)slider;

- (void)sliderReachEnd:(CaptchaSlider *)slider;

@end

@interface CaptchaSlider : UIView

@property (nonatomic, strong) UIImage *thumbImage;
@property (nonatomic, strong) UIImage *finishImage;
@property (nonatomic, copy) NSString *backgroundText;
@property (nonatomic, copy) NSString *foregroundText;
@property (nonatomic, strong)UIFont *font;
@property (nonatomic, assign) BOOL needThumbBack;        //拖动后是否返回
@property (nonatomic, assign) BOOL needEndReact;        //拖到终点后是否继续对用户事件反应,即拖动框是否停在终点
@property (nonatomic, assign) CGFloat value;
@property (nonatomic, weak) id<CaptchaSliderDelegate> delegate;


- (void)setSliderValue:(CGFloat)value;

- (void)setColorForBackground:(UIColor *)background foreground:(UIColor *)foreground thumb:(UIColor *)thumb border:(UIColor *)border backgroundTextColor:(UIColor *)textColor foregroundTextColor:(UIColor *)foregroundTextColor;

@end
