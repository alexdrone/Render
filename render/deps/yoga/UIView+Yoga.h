/**
 * Copyright (c) 2014-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "YGLayout.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^YGLayoutConfigurationBlock)(YGLayout *);

@interface UIView (Yoga)

/**
 The YGLayout that is attached to this view. It is lazily created.
 */
@property (nonatomic, readonly, strong) YGLayout *yoga;
/**
 Indicates whether or not Yoga is enabled
 */
@property (nonatomic, readonly, assign) BOOL isYogaEnabled;

/**
 In ObjC land, every time you access `view.yoga.*` you are adding another `objc_msgSend`
 to your code. If you plan on making multiple changes to YGLayout, it's more performant
 to use this method, which uses a single objc_msgSend call.
 */
- (void)configureLayoutWithBlock:(YGLayoutConfigurationBlock)block
NS_SWIFT_NAME(configureLayout(block:));

@end

extern UIView * _Nullable YGBuild(NSString *className);
extern void YGSet(UIView *view, NSDictionary *properties, NSDictionary *animators);
extern NSString *YGReplaceKeyIfNecessary(NSString *key);
extern NSArray *YGUIKitSymbols(void);

// Render Additions.

@interface UIView (YGAdditions)
///Redirects to 'layer.cornerRadius'
@property (nonatomic, assign) CGFloat cornerRadius;
///Redirects to 'layer.borderWidth'
@property (nonatomic, assign) CGFloat borderWidth;
///Redirects to 'layer.borderColor'
@property (nonatomic, strong) UIColor *borderColor;
///The opacity of the shadow. Defaults to 0. Specifying a value outside the
@property (nonatomic, assign) CGFloat shadowOpacity;
///The blur radius used to create the shadow. Defaults to 3.
@property (nonatomic, assign) CGFloat shadowRadius;
///The shadow offset. Defaults to (0, -3)
@property (nonatomic, assign) CGSize shadowOffset;
///The color of the shadow. Defaults to opaque black.
@property (nonatomic, strong) UIColor *shadowColor;
@end

@interface UIButton (YGAdditions)
////Symeetrical to  -[UIButton titleForState:]
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *highlightedText;
@property (nonatomic, strong) NSString *selectedText;
@property (nonatomic, strong) NSString *disabledText;
//Symeetrical to  -[UIButton titleColorForState:]
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *highlightedTextColor;
@property (nonatomic, strong) UIColor *selectedTextColor;
@property (nonatomic, strong) UIColor *disabledTextColor;
@property (nonatomic, strong) UIColor *backgroundColorImage;
////Symmetrical to -[UIButton backgroundImageForState:]
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) UIImage *highlightedBackgroundImage;
@property (nonatomic, strong) UIImage *selectedBackgroundImage;
@property (nonatomic, strong) UIImage *disabledBackgroundImage;
//Symmetrical to -[UIButton imageForState:]
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *highlightedImage;
@property (nonatomic, strong) UIImage *selectedImage;
@property (nonatomic, strong) UIImage *disabledImage;
@end

@interface UIImage (YGAdditions)
+ (UIImage*)yg_imageWithColor:(UIColor*)color;
+ (UIImage*)yg_imageWithColor:(UIColor*)color size:(CGSize)size;
+ (UIImage*)yg_imageFromString:(NSString *)string
                         color:(UIColor*)color
                          font:(UIFont *)font
                          size:(CGSize)size;
@end

@interface UIViewController (YGAdditions)
- (BOOL)isModal;
@end

extern UIViewController * _Nullable UIGetTopmostViewController(void);

NS_ASSUME_NONNULL_END

