/**
 * Copyright (c) 2014-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "UIView+Yoga.h"
#import "YGLayout+Private.h"
#import "YGPercentLayout.h"
#import <objc/runtime.h>

static const void *kYGYogaAssociatedKey = &kYGYogaAssociatedKey;

@implementation UIView (YogaKit)

- (YGLayout *)yoga
{
  YGLayout *yoga = objc_getAssociatedObject(self, kYGYogaAssociatedKey);
  if (!yoga) {
    yoga = [[YGLayout alloc] initWithView:self];
    objc_setAssociatedObject(self, kYGYogaAssociatedKey, yoga, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return yoga;
}

- (BOOL)isYogaEnabled
{
  return objc_getAssociatedObject(self, kYGYogaAssociatedKey) != nil;
}

- (void)configureLayoutWithBlock:(YGLayoutConfigurationBlock)block
{
  if (block != nil) {
    block(self.yoga);
  }
}

@end

UIView *YGBuild(NSString *className) {
  return [[NSClassFromString(className) alloc] init];
}

void YGSet(UIView *view, NSDictionary *properties, NSDictionary *animators) {
  for (NSString *key in [properties allKeys]) {
    NSString *keyPath = YGReplaceKeyIfNecessary(key);
    if ([view respondsToSelector: NSSelectorFromString(keyPath)]
        || [view.yoga respondsToSelector:NSSelectorFromString(key)]) {
      if (animators[key] != nil) {
        UIViewPropertyAnimator *animator = animators[key];
        [animator addAnimations:^{
          [view setValue:properties[key] forKeyPath:keyPath];
        }];
        [animator startAnimation];
      } else {
        [view setValue:properties[key] forKeyPath:keyPath];
      }
    }
  }
}

static NSArray *UIKitSymbols = nil;
NSArray *YGUIKitSymbols() {
  if (UIKitSymbols == nil) UIKitSymbols = @[
                                            @"UIButton",
                                            @"UICollectionView",
                                            @"UIControl",
                                            @"UIImageView",
                                            @"UILabel",
                                            @"UIProgressView",
                                            @"UIScrollView",
                                            @"UISearchBar",
                                            @"UISegmentedControl",
                                            @"UISlider",
                                            @"UIStackView",
                                            @"UIStepper",
                                            @"UISwitch",
                                            @"UITableView",
                                            @"UITableViewHeaderFooterView",
                                            @"UITextField",
                                            @"UITextView",
                                            @"UIView",
                                            @"UIWebView",
                                            @"WKWebView"];
  return UIKitSymbols;
}
static NSSet<NSString *> *YGProp = nil;
NSString *YGReplaceKeyIfNecessary(NSString *key) {
  if (YGProp == nil) YGProp = [[NSSet<NSString *> alloc] initWithArray: @[
                                                                          @"direction",
                                                                          @"flexDirection",
                                                                          @"justifyContent",
                                                                          @"alignContent",
                                                                          @"alignItems",
                                                                          @"alignSelf",
                                                                          @"positionType",
                                                                          @"flexWrap",
                                                                          @"overflow",
                                                                          @"display",
                                                                          @"flex",
                                                                          @"flexGrow",
                                                                          @"flexShrink",
                                                                          @"flexBasis",
                                                                          @"margin",
                                                                          @"marginTop",
                                                                          @"marginBottom",
                                                                          @"marginLeft",
                                                                          @"marginRight",
                                                                          @"padding",
                                                                          @"paddingTop",
                                                                          @"paddingBottom",
                                                                          @"paddingLeft",
                                                                          @"paddingRight",
                                                                          @"width",
                                                                          @"height",
                                                                          @"minWidth",
                                                                          @"minHeight",
                                                                          @"maxWidth",
                                                                          @"maxHeight"]];
  if ([YGProp containsObject:key]) {
    return [NSString stringWithFormat:@"%@.%@", @"yoga", key];
  }
  return key;
}

#pragma mark - Render Additions

@implementation UIView (YGAdditions)

- (CGFloat)cornerRadius {
  return self.layer.cornerRadius;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
  self.clipsToBounds = YES;
  self.layer.cornerRadius = cornerRadius;
}

- (CGFloat)borderWidth {
  return self.layer.borderWidth;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
  self.layer.borderWidth = borderWidth;
}

- (UIColor*)borderColor {
  return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void)setBorderColor:(UIColor*)borderColor {
  self.layer.borderColor = borderColor.CGColor;
}

- (CGFloat)paddingLeft {
  return 0;
}

- (CGFloat)shadowOpacity {
  return self.layer.shadowOpacity;
}

- (void)setShadowOpacity:(CGFloat)shadowOpacity {
  self.layer.shadowOpacity = shadowOpacity;
}

- (CGFloat)shadowRadius {
  return self.layer.shadowRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius {
  self.layer.shadowRadius = shadowRadius;
}

- (CGSize)shadowOffset {
  return self.layer.shadowOffset;
}

- (void)setShadowOffset:(CGSize)shadowOffset {
  self.layer.shadowOffset = shadowOffset;
}

- (UIColor*)shadowColor {
  return [UIColor colorWithCGColor:self.layer.shadowColor];
}

- (void)setShadowColor:(UIColor*)shadowColor {
  self.layer.shadowColor = shadowColor.CGColor;
}

@end

#pragma mark - UIButton

@implementation UIButton (YGAdditions)

- (NSString*)text {
  return [self titleForState:UIControlStateNormal];
}

- (void)setText:(NSString*)text {
  [self setTitle:text forState:UIControlStateNormal];
}

- (NSString*)highlightedText {
  return [self titleForState:UIControlStateHighlighted];
}

- (void)setHighlightedText:(NSString*)highlightedText {
  [self setTitle:highlightedText forState:UIControlStateHighlighted];
}

- (NSString*)selectedText {
  return [self titleForState:UIControlStateSelected];
}

-  (void)setSelectedText:(NSString*)selectedText {
  [self setTitle:selectedText forState:UIControlStateSelected];
}

- (NSString*)disabledText {
  return [self titleForState:UIControlStateDisabled];
}

- (void)setDisabledText:(NSString*)disabledText {
  [self setTitle:disabledText forState:UIControlStateDisabled];
}

- (UIColor*)textColor {
  return [self titleColorForState:UIControlStateNormal];
}

- (void)setTextColor:(UIColor*)textColor {
  [self setTitleColor:textColor forState:UIControlStateNormal];
}

- (UIColor*)highlightedTextColor {
  return [self titleColorForState:UIControlStateHighlighted];
}

- (void)setHighlightedTextColor:(UIColor*)highlightedTextColor {
  [self setTitleColor:highlightedTextColor forState:UIControlStateHighlighted];
}

- (UIColor*)selectedTextColor {
  return [self titleColorForState:UIControlStateSelected];
}

- (void)setSelectedTextColor:(UIColor*)selectedTextColor {
  [self setTitleColor:selectedTextColor forState:UIControlStateSelected];
}

- (UIColor*)disabledTextColor {
  return [self titleColorForState:UIControlStateDisabled];
}

- (void)setDisabledTextColor:(UIColor*)disabledTextColor {
  [self setTitleColor:disabledTextColor forState:UIControlStateDisabled];
}

- (UIColor *)backgroundColorImage {
  return nil;
}

- (void)setBackgroundColorImage:(UIColor*)backgroundColor {
  UIImage *image = [UIImage yg_imageWithColor:backgroundColor];
  self.backgroundImage = image;
}

- (UIImage*)backgroundImage {
  return [self backgroundImageForState:UIControlStateNormal];
}

- (void)setBackgroundImage:(UIImage*)backgroundImage {
  [self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
}

- (UIImage*)highlightedBackgroundImage {
  return [self backgroundImageForState:UIControlStateHighlighted];
}

- (void)setHighlightedBackgroundImage:(UIImage*)highlightedBackgroundImage {
  [self setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
}

- (UIImage*)selectedBackgroundImage {
  return [self backgroundImageForState:UIControlStateSelected];
}

- (void)setSelectedBackgroundImage:(UIImage*)selectedBackgroundImage {
  [self setBackgroundImage:selectedBackgroundImage forState:UIControlStateSelected];
}

- (UIImage*)disabledBackgroundImage {
  return [self backgroundImageForState:UIControlStateDisabled];
}

- (void)setDisabledBackgroundImage:(UIImage*)disabledBackgroundImage {
  [self setBackgroundImage:disabledBackgroundImage forState:UIControlStateDisabled];
}

- (UIImage*)image {
  return [self imageForState:UIControlStateNormal];
}

- (void)setImage:(UIImage*)image {
  [self setImage:image forState:UIControlStateNormal];
}

- (UIImage*)highlightedImage {
  return [self imageForState:UIControlStateHighlighted];
}

- (void)setHighlightedImage:(UIImage*)highlightedImage {
  [self setImage:highlightedImage forState:UIControlStateHighlighted];
}

- (UIImage*)selectedImage {
  return [self imageForState:UIControlStateSelected];
}

- (void)setSelectedImage:(UIImage*)selectedImage {
  [self setImage:selectedImage forState:UIControlStateSelected];
}

- (UIImage*)disabledImage {
  return [self imageForState:UIControlStateDisabled];
}

- (void)setDisabledImage:(UIImage*)disabledImage {
  [self setImage:disabledImage forState:UIControlStateDisabled];
}

@end

#pragma mark - UIImage

@implementation UIImage (YGAdditions)

+ (UIImage*)yg_imageWithColor:(UIColor*)color {
  return [self yg_imageWithColor:color size:(CGSize){1,1}];
}

+ (UIImage*)yg_imageWithColor:(UIColor*)color size:(CGSize)size {
  CGRect rect = (CGRect){CGPointZero, size};
  UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextFillRect(context, rect);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

+ (UIImage*)yg_imageFromString:(NSString *)string
                         color:(UIColor*)color
                          font:(UIFont *)font
                          size:(CGSize)size {
  UIGraphicsBeginImageContextWithOptions(size, NO, 0);

  NSDictionary *attributes = @{NSFontAttributeName: font,
                               NSForegroundColorAttributeName: color };
  [string drawInRect:CGRectMake(0, 0, size.width, size.height)
      withAttributes:attributes];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return image;
}

@end

@implementation UIViewController (YGAdditions)

- (BOOL)isModal {
  if ([self presentingViewController])
    return YES;
  if (
      [[[self navigationController] presentingViewController] presentedViewController]
      == [self navigationController])
    return YES;
  if ([[[self tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]])
    return YES;
  return NO;
}

@end

UIViewController * _Nullable UIGetTopmostViewController() {
  UIViewController *baseVC = UIApplication.sharedApplication.keyWindow.rootViewController;
  if ([baseVC isKindOfClass:[UINavigationController class]]) {
    return ((UINavigationController *)baseVC).visibleViewController;
  }
  if ([baseVC isKindOfClass:[UITabBarController class]]) {
    UIViewController *selectedTVC = ((UITabBarController*)baseVC).selectedViewController;
    if (selectedTVC) {
      return selectedTVC;
    }
  }
  if (baseVC.presentedViewController) {
    return baseVC.presentedViewController;
  }
  return baseVC;
}

