//
//  CaptchaSlider.m
//  CaptchaDemo
//
//  Created by alex on 20/04/2017.
//  Licence: WTFPL
//

#import "CaptchaSlider.h"

#define kSliderW self.bounds.size.width
#define kSliderH self.bounds.size.height
#define kCornerRadius 5.0  //默认圆角为5
#define kBorderWidth 0.2 //默认边框为2
#define kAnimationDuration 0.5 //默认动画移速
#define kForegroundColor [UIColor orangeColor] //默认滑过颜色
#define kBackgroundColor [UIColor darkGrayColor] //默认未滑过颜色
#define kThumbColor [UIColor lightGrayColor] //默认Thumb颜色
#define kBorderColor [UIColor blackColor] //默认边框颜色
#define kThumbW 15 //默认的thumb的宽度

@implementation CaptchaSlider {
    UILabel *_backgroundLabel;
    UILabel *_foregroundLabel;
    UIImageView *_thumbImageView;
    UIView *_foregroundView;
    UIView *_backgroundView;
    UIView *_touchView;
    BOOL _stopReact;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initView];
    }
    return self;
}

- (void)initView {
    _backgroundLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _backgroundLabel.textAlignment = NSTextAlignmentCenter;
    _backgroundLabel.font = [UIFont systemFontOfSize:20];
    
    _foregroundLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _foregroundLabel.textAlignment = NSTextAlignmentCenter;
    _foregroundLabel.font = [UIFont systemFontOfSize:20];
    
    _foregroundView = [[UIView alloc] init];
    _foregroundView.clipsToBounds = YES;
    [_foregroundView addSubview:_foregroundLabel];
    [self addSubview:_foregroundView];
    _thumbImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _thumbImageView.layer.cornerRadius = kCornerRadius;
    _thumbImageView.layer.masksToBounds = YES;
    _thumbImageView.userInteractionEnabled = YES;
    [self addSubview:_thumbImageView];
    self.layer.cornerRadius = kCornerRadius;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = kBorderWidth;
    [self setSliderValue:0.0];
    //默认配置
    self.needThumbBack = YES;
    self.needEndReact = YES;
    self.backgroundColor = kBackgroundColor;
    _foregroundView.backgroundColor = kForegroundColor;
    _thumbImageView.backgroundColor = kThumbColor;
    [self.layer setBorderColor:kBorderColor.CGColor];
    _touchView = _thumbImageView;
}

- (void)setBackgroundText:(NSString *)text {
    _backgroundText = text;
    _backgroundLabel.text = text;
    if (!_backgroundLabel.superview) {
        [self insertSubview:_backgroundLabel atIndex:0];
    }
}

- (void)setForegroundText:(NSString *)text {
    _foregroundText = text;
    _foregroundLabel.text = text;
//    if (!_foregroundLabel.superview) {
//        [self insertSubview:_foregroundLabel atIndex:1];
//    }
}

- (void)setFont:(UIFont *)font {
    _font = font;
    _backgroundLabel.font = font;
    _foregroundLabel.font = font;
}

- (void)setSliderValue:(CGFloat)value {
    [self setSliderValue:value animation:NO completion:nil];
}

- (void)setSliderValue:(CGFloat)value animation:(BOOL)animation completion:(void (^)(BOOL))completion {
    if (value > 1) {
        value = 1;
    }
    if (value < 1) {
        value = 0;
    }
    CGPoint point = CGPointMake(value * kSliderW, 0);
    typeof(self) weakSelf = self;
    if (animation) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            [weakSelf fillForegroundViewWithPoint:point];
        } completion:^(BOOL finished) {
            if (completion) {
                completion(finished);
            }
        }];
    }
    else {
        [self fillForegroundViewWithPoint:point];
    }
}

- (void)fillForegroundViewWithPoint:(CGPoint)point {
    if (_stopReact) {
        return;
    }
    CGFloat thumbW = (_thumbImage)?_thumbImage.size.width : kThumbW;
    CGPoint p = point;
    
    p.x += thumbW/2;
    if (p.x > kSliderW) {
        p.x = kSliderW;
    }
    if (p.x < 0) {
        p.x = 0;
    }
    if (_finishImage) {
        _thumbImageView.image = (point.x < (kSliderW - thumbW / 2))? _thumbImage : _finishImage;
    }
    self.value = p.x / kSliderW;
    if ( point.x < 0) {
        return;
    }
    
    _foregroundView.frame = CGRectMake(0, 0, (point.x > kSliderW)? kSliderW : point.x, kSliderH);
    
    if (_foregroundView.frame.size.width <= thumbW / 2) {
        _thumbImageView.frame = CGRectMake(0, kBorderWidth, thumbW, _foregroundView.frame.size.height - kBorderWidth);
    }
    else if (_foregroundView.frame.size.width >= kSliderW - thumbW/2) {
        _thumbImageView.frame = CGRectMake(kSliderW - thumbW, kBorderWidth, thumbW, _foregroundView.frame.size.height - 2 * kBorderWidth);
        if (_needEndReact) {
            _stopReact = true;
        }
        if ([self.delegate respondsToSelector:@selector(sliderReachEnd:)]) {
            [self.delegate sliderReachEnd:self];
        }
    }
    else {
        _thumbImageView.frame = CGRectMake(_foregroundView.frame.size.width - thumbW / 2, kBorderWidth, thumbW, _foregroundView.frame.size.height - 2 * kBorderWidth);
    }
}

- (void)setColorForBackground:(UIColor *)background foreground:(UIColor *)foreground thumb:(UIColor *)thumb border:(UIColor *)border backgroundTextColor:(UIColor *)textColor foregroundTextColor:(UIColor *)foregroundTextColor{
    self.backgroundColor = background;
    _foregroundView.backgroundColor = foreground;
    _thumbImageView.backgroundColor = thumb;
    self.layer.backgroundColor = border.CGColor;
    _backgroundLabel.textColor = textColor;
    _foregroundLabel.textColor = foregroundTextColor;
}

- (void)setThumbImage:(UIImage *)thumbImage {
    _thumbImage = thumbImage;
    _thumbImageView.image = thumbImage;
    [_thumbImageView sizeToFit];
    [self setSliderValue:0.0f];
}

#pragma mark ------------------ touch ------------------

//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    UITouch *touch = [touches anyObject];
//    if (touch.view == _thumbImageView) {
//        return;
//    }
//    CGPoint point = [touch locationInView:self];
//    [self fillForegroundViewWithPoint:point];
//}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch.view != _touchView) {
        return;
    }
    CGPoint point = [touch locationInView:self];
//    if (point.x > kSliderW) {
//        [super touchesBegan:touches withEvent:event];
//        [self.nextResponder touchesBegan:touches withEvent:event];
//        return;
//    }
    [self fillForegroundViewWithPoint:point];
    if ([self.delegate respondsToSelector:@selector(sliderValueChanging:)]) {
        [self.delegate sliderValueChanging:self];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch.view != _touchView) {
        return;
    }
    CGPoint __block point = [touch locationInView:self];
    if ([self.delegate respondsToSelector:@selector(sliderEndValueChanged:)]) {
        [self.delegate sliderEndValueChanged:self];
    }
    typeof(self) weakSelf = self;
    if (_needThumbBack) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            point.x = 0;
            [weakSelf fillForegroundViewWithPoint:point];
        }];
    }
}

@end
