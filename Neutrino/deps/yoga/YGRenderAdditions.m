#import "YGRenderAdditions.h"
#import <objc/runtime.h>

#pragma mark - UIView

@implementation UIView (YGAdditions)

- (CGFloat)cornerRadius
{
  return self.layer.cornerRadius;
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
  self.clipsToBounds = YES;
  self.layer.cornerRadius = cornerRadius;
}

- (CGFloat)borderWidth
{
  return self.layer.borderWidth;
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
  self.layer.borderWidth = borderWidth;
}

- (UIColor*)borderColor
{
  return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void)setBorderColor:(UIColor*)borderColor
{
  self.layer.borderColor = borderColor.CGColor;
}

- (CGFloat)paddingLeft
{
  return 0;
}

- (CGFloat)shadowOpacity
{
  return self.layer.shadowOpacity;
}

- (void)setShadowOpacity:(CGFloat)shadowOpacity
{
  self.layer.shadowOpacity = shadowOpacity;
}

- (CGFloat)shadowRadius
{
  return self.layer.shadowRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius
{
  self.layer.shadowRadius = shadowRadius;
}

- (CGSize)shadowOffset
{
  return self.layer.shadowOffset;
}

- (void)setShadowOffset:(CGSize)shadowOffset
{
  self.layer.shadowOffset = shadowOffset;
}

- (UIColor*)shadowColor
{
  return [UIColor colorWithCGColor:self.layer.shadowColor];
}

- (void)setShadowColor:(UIColor*)shadowColor
{
  self.layer.shadowColor = shadowColor.CGColor;
}

@end

#pragma mark - UIButton

@implementation UIButton (YGAdditions)

- (NSString*)text
{
  return [self titleForState:UIControlStateNormal];
}

- (void)setText:(NSString*)text
{
  [self setTitle:text forState:UIControlStateNormal];
}

- (NSString*)highlightedText
{
  return [self titleForState:UIControlStateHighlighted];
}

- (void)setHighlightedText:(NSString*)highlightedText
{
  [self setTitle:highlightedText forState:UIControlStateHighlighted];
}

- (NSString*)selectedText
{
  return [self titleForState:UIControlStateSelected];
}

-  (void)setSelectedText:(NSString*)selectedText
{
  [self setTitle:selectedText forState:UIControlStateSelected];
}

- (NSString*)disabledText
{
  return [self titleForState:UIControlStateDisabled];
}

- (void)setDisabledText:(NSString*)disabledText
{
  [self setTitle:disabledText forState:UIControlStateDisabled];
}

- (UIColor*)textColor
{
  return [self titleColorForState:UIControlStateNormal];
}

- (void)setTextColor:(UIColor*)textColor
{
  [self setTitleColor:textColor forState:UIControlStateNormal];
}

- (UIColor*)highlightedTextColor
{
  return [self titleColorForState:UIControlStateHighlighted];
}

- (void)setHighlightedTextColor:(UIColor*)highlightedTextColor
{
  [self setTitleColor:highlightedTextColor forState:UIControlStateHighlighted];
}

- (UIColor*)selectedTextColor
{
  return [self titleColorForState:UIControlStateSelected];
}

- (void)setSelectedTextColor:(UIColor*)selectedTextColor
{
  [self setTitleColor:selectedTextColor forState:UIControlStateSelected];
}

- (UIColor*)disabledTextColor
{
  return [self titleColorForState:UIControlStateDisabled];
}

- (void)setDisabledTextColor:(UIColor*)disabledTextColor
{
  [self setTitleColor:disabledTextColor forState:UIControlStateDisabled];
}

- (void)setBackgroundColorImage:(UIColor*)backgroundColor
{
  UIImage *image = [UIImage REFL_imageWithColor:backgroundColor];
  self.backgroundImage = image;
}

- (UIImage*)backgroundImage
{
  return [self backgroundImageForState:UIControlStateNormal];
}

- (void)setBackgroundImage:(UIImage*)backgroundImage
{
  [self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
}

- (UIImage*)highlightedBackgroundImage
{
  return [self backgroundImageForState:UIControlStateHighlighted];
}

- (void)setHighlightedBackgroundImage:(UIImage*)highlightedBackgroundImage
{
  [self setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
}

- (UIImage*)selectedBackgroundImage
{
  return [self backgroundImageForState:UIControlStateSelected];
}

- (void)setSelectedBackgroundImage:(UIImage*)selectedBackgroundImage
{
  [self setBackgroundImage:selectedBackgroundImage forState:UIControlStateSelected];
}

- (UIImage*)disabledBackgroundImage
{
  return [self backgroundImageForState:UIControlStateDisabled];
}

- (void)setDisabledBackgroundImage:(UIImage*)disabledBackgroundImage
{
  [self setBackgroundImage:disabledBackgroundImage forState:UIControlStateDisabled];
}

- (UIImage*)image
{
  return [self imageForState:UIControlStateNormal];
}

- (void)setImage:(UIImage*)image
{
  [self setImage:image forState:UIControlStateNormal];
}

- (UIImage*)highlightedImage
{
  return [self imageForState:UIControlStateHighlighted];
}

- (void)setHighlightedImage:(UIImage*)highlightedImage
{
  [self setImage:highlightedImage forState:UIControlStateHighlighted];
}

- (UIImage*)selectedImage
{
  return [self imageForState:UIControlStateSelected];
}

- (void)setSelectedImage:(UIImage*)selectedImage
{
  [self setImage:selectedImage forState:UIControlStateSelected];
}

- (UIImage*)disabledImage
{
  return [self imageForState:UIControlStateDisabled];
}

- (void)setDisabledImage:(UIImage*)disabledImage
{
  [self setImage:disabledImage forState:UIControlStateDisabled];
}

@end

#pragma mark - UIImage

@implementation UIImage (YGAdditions)

+ (UIImage*)REFL_imageWithColor:(UIColor*)color
{
  return [self REFL_imageWithColor:color size:(CGSize){1,1}];
}

+ (UIImage*)REFL_imageWithColor:(UIColor*)color size:(CGSize)size
{
  CGRect rect = (CGRect){CGPointZero, size};
  UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextFillRect(context, rect);

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return image;
}

@end

@implementation NSObject (YGAdditions)

- (NSString*)refl_className
{
  NSString *className = NSStringFromClass(self.class);

  if ([className hasPrefix:@"Optional("]) {
    className = [className stringByReplacingOccurrencesOfString:@"Optional(\"" withString:@""];
    className = [className stringByReplacingOccurrencesOfString:@"\")" withString:@""];
  }

  return className;
}

- (Class)refl_class
{
  return self.class;
}

@end



