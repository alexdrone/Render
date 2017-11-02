#import "YGRenderAdditions.h"
#import <objc/runtime.h>

#pragma mark - UIView

@implementation UIView (REFLAdditions)

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

@implementation UIButton (REFLAdditions)

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

- (void)setBackgroundColor:(UIColor*)backgroundColor
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

@implementation UIImage (REFLAdditions)

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

@implementation NSObject (REFLAspects)

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

#pragma mark - UIColor

typedef struct {
  CGFloat a, b, c;
} CMRFloatTriple;

typedef struct {
  CGFloat a, b, c, d;
} CMRFloatQuad;

//REFLLESS uses HSL, but we have to specify UIColor as HSB
static inline CMRFloatTriple HSB2HSL(CGFloat hue, CGFloat saturation, CGFloat brightness);
static inline CMRFloatTriple HSL2HSB(CGFloat hue, CGFloat saturation, CGFloat lightness);

@implementation UIColor (HTMLColors)


+ (UIColor*)gradientFromColor:(UIColor*)color1 toColor:(UIColor*)color2 withSize:(CGSize)frame
{
  NSArray *colors = [NSArray arrayWithObjects:(id)color1.CGColor, (id)color2.CGColor, nil];

  //Allocate color space
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  //Allocate the gradients
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, NULL);

  //Allocate bitmap context
  //The pattern is vertical - it doesn't require the whole width
  CGContextRef bitmapContext = CGBitmapContextCreate(NULL, 1., frame.height, 8, 4 * frame.width, colorSpace, kCGImageAlphaNoneSkipFirst);
  //Draw Gradient Here
  CGContextDrawLinearGradient(bitmapContext, gradient, CGPointMake(0.0f, 0.0f), CGPointMake(0, frame.height), (CGGradientDrawingOptions)kCGImageAlphaNoneSkipFirst);
  //Create a CGImage from context
  CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
  //Create a UIImage from CGImage
  UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
  //Release the CGImage
  CGImageRelease(cgImage);
  //Release the bitmap context
  CGContextRelease(bitmapContext);
  //Release the color space
  CGColorSpaceRelease(colorSpace);
  //Release the gradient
  CGGradientRelease(gradient);

  return [UIColor colorWithPatternImage:uiImage];
}

+ (UIColor*)refl_colorWithCSSColor:(NSString *)cssColor
{
  UIColor *color = nil;
  NSScanner *scanner = [NSScanner scannerWithString:cssColor];
  [scanner scanLESSColor:&color];
  return (scanner.isAtEnd) ? color : nil;
}

+ (UIColor *)colorWithHexString:(NSString *)hexColor
{
  UIColor *color = nil;
  NSScanner *scanner = [NSScanner scannerWithString:hexColor];
  [scanner scanHexColor:&color];
  return (scanner.isAtEnd) ? color : nil;
}

+ (UIColor *)colorWithRGBString:(NSString *)rgbColor
{
  UIColor *color = nil;
  NSScanner *scanner = [NSScanner scannerWithString:rgbColor];
  [scanner scanRGBColor:&color];
  return (scanner.isAtEnd) ? color : nil;
}

+ (UIColor *)colorWithHSLString:(NSString *)hslColor
{
  UIColor *color = nil;
  NSScanner *scanner = [NSScanner scannerWithString:hslColor];
  [scanner scanHSLColor:&color];
  return (scanner.isAtEnd) ? color : nil;
}


static inline unsigned ToByte(CGFloat f)
{
  f = MAX(0, MIN(f, 1)); //Clamp
  return (unsigned)round(f * 255);
}

- (NSString *)hexStringValue
{
  NSString *hex = nil;
  CGFloat red, green, blue, alpha;
  if ([self cmr_getRed:&red green:&green blue:&blue alpha:&alpha]) {
    hex = [NSString stringWithFormat:@"#%02X%02X%02X",
           ToByte(red), ToByte(green), ToByte(blue)];
  }
  return hex;
}

- (NSString *)rgbStringValue
{
  NSString *rgb = nil;
  CGFloat red, green, blue, alpha;
  if ([self cmr_getRed:&red green:&green blue:&blue alpha:&alpha]) {
    if (alpha == 1.0) {
      rgb = [NSString stringWithFormat:@"rgb(%u, %u, %u)",
             ToByte(red), ToByte(green), ToByte(blue)];
    } else {
      rgb = [NSString stringWithFormat:@"rgba(%u, %u, %u, %g)",
             ToByte(red), ToByte(green), ToByte(blue), alpha];
    }
  }
  return rgb;
}

static inline unsigned ToDeg(CGFloat f)
{
  return (unsigned)round(f * 360) % 360;
}

static inline unsigned ToPercentage(CGFloat f)
{
  f = MAX(0, MIN(f, 1)); //Clamp
  return (unsigned)round(f * 100);
}

- (NSString *)hslStringValue
{
  NSString *hsl = nil;
  CGFloat hue, saturation, brightness, alpha;
  if ([self cmr_getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
    CMRFloatTriple hslVal = HSB2HSL(hue, saturation, brightness);
    if (alpha == 1.0) {
      hsl = [NSString stringWithFormat:@"hsl(%u, %u%%, %u%%)",
             ToDeg(hslVal.a), ToPercentage(hslVal.b), ToPercentage(hslVal.c)];
    } else {
      hsl = [NSString stringWithFormat:@"hsla(%u, %u%%, %u%%, %g)",
             ToDeg(hslVal.a), ToPercentage(hslVal.b), ToPercentage(hslVal.c), alpha];
    }
  }
  return hsl;
}

//Fix up getting color components
- (BOOL)cmr_getRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha
{
  if ([self getRed:red green:green blue:blue alpha:alpha]) {
    return YES;
  }

  CGFloat white;
  if ([self getWhite:&white alpha:alpha]) {
    if (red)
      *red = white;
    if (green)
      *green = white;
    if (blue)
      *blue = white;
    return YES;
  }

  return NO;
}

- (BOOL)cmr_getHue:(CGFloat *)hue saturation:(CGFloat *)saturation brightness:(CGFloat *)brightness alpha:(CGFloat *)alpha
{
  if ([self getHue:hue saturation:saturation brightness:brightness alpha:alpha]) {
    return YES;
  }

  CGFloat white;
  if ([self getWhite:&white alpha:alpha]) {
    if (hue)
      *hue = 0;
    if (saturation)
      *saturation = 0;
    if (brightness)
      *brightness = white;
    return YES;
  }

  return NO;
}


@end


@implementation NSScanner (HTMLColors)

- (BOOL)scanLESSColor:(UIColor **)color
{
  return [self scanHexColor:color]
  || [self scanRGBColor:color]
  || [self scanHSLColor:color]
  || [self cmr_scanTransparent:color];
}

- (BOOL)scanRGBColor:(UIColor **)color
{
  return [self cmr_caseInsensitiveWithCleanup:^BOOL{
    if ([self scanString:@"rgba" intoString:NULL]) {
      CMRFloatQuad scale = {1.0/255.0, 1.0/255.0, 1.0/255.0, 1.0};
      CMRFloatQuad q;
      if ([self cmr_scanFloatQuad:&q scale:scale]) {
        if (color) {
          *color = [UIColor colorWithRed:q.a green:q.b blue:q.c alpha:q.d];
        }
        return YES;
      }
    } else if ([self scanString:@"rgb" intoString:NULL]) {
      CMRFloatTriple scale = {1.0/255.0, 1.0/255.0, 1.0/255.0};
      CMRFloatTriple t;
      if ([self cmr_scanFloatTriple:&t scale:scale]) {
        if (color) {
          *color = [UIColor colorWithRed:t.a green:t.b blue:t.c alpha:1.0];
        }
        return YES;
      }
    }
    return NO;
  }];
}

//Wrap hues in a circle, where [0,1] = [0°,360°]
static inline CGFloat CMRNormHue(CGFloat hue)
{
  return hue - floor(hue);
}

- (BOOL)scanHSLColor:(UIColor **)color
{
  return [self cmr_caseInsensitiveWithCleanup:^BOOL{
    if ([self scanString:@"hsla" intoString:NULL]) {
      CMRFloatQuad scale = {1.0/360.0, 1.0, 1.0, 1.0};
      CMRFloatQuad q;
      if ([self cmr_scanFloatQuad:&q scale:scale]) {
        if (color) {
          CMRFloatTriple t = HSL2HSB(CMRNormHue(q.a), q.b, q.c);
          *color = [UIColor colorWithHue:t.a saturation:t.b brightness:t.c alpha:q.d];
        }
        return YES;
      }
    } else if ([self scanString:@"hsl" intoString:NULL]) {
      CMRFloatTriple scale = {1.0/360.0, 1.0, 1.0};
      CMRFloatTriple t;
      if ([self cmr_scanFloatTriple:&t scale:scale]) {
        if (color) {
          t = HSL2HSB(CMRNormHue(t.a), t.b, t.c);
          *color = [UIColor colorWithHue:t.a saturation:t.b brightness:t.c alpha:1.0];
        }
        return YES;
      }
    }
    return NO;
  }];
}

- (BOOL)scanHexColor:(UIColor **)color
{
  return [self cmr_resetScanLocationOnFailure:^BOOL{
    return [self scanString:@"#" intoString:NULL]
    && [self cmr_scanHexTriple:color];
  }];
}


#pragma mark - Private

- (void)cmr_withSkip:(NSCharacterSet *)chars run:(void (^)(void))block
{
  NSCharacterSet *skipped = self.charactersToBeSkipped;
  self.charactersToBeSkipped = chars;
  block();
  self.charactersToBeSkipped = skipped;
}

- (void)cmr_withNoSkip:(void (^)(void))block
{
  NSCharacterSet *skipped = self.charactersToBeSkipped;
  self.charactersToBeSkipped = nil;
  block();
  self.charactersToBeSkipped = skipped;
}

- (NSRange)cmr_rangeFromScanLocation
{
  NSUInteger loc = self.scanLocation;
  NSUInteger len = self.string.length - loc;
  return NSMakeRange(loc, len);
}

- (void)cmr_skipCharactersInSet:(NSCharacterSet *)chars
{
  [self cmr_withNoSkip:^{
    [self scanCharactersFromSet:chars intoString:NULL];
  }];
}

- (void)cmr_skip
{
  [self cmr_skipCharactersInSet:self.charactersToBeSkipped];
}

- (BOOL)cmr_resetScanLocationOnFailure:(BOOL (^)(void))block
{
  NSUInteger initialScanLocation = self.scanLocation;
  if (!block()) {
    self.scanLocation = initialScanLocation;
    return NO;
  }
  return YES;
}

- (BOOL)cmr_caseInsensitiveWithCleanup:(BOOL (^)(void))block
{
  NSUInteger initialScanLocation = self.scanLocation;
  BOOL caseSensitive = self.caseSensitive;
  self.caseSensitive = NO;

  BOOL success = block();
  if (!success) {
    self.scanLocation = initialScanLocation;
  }

  self.caseSensitive = caseSensitive;
  return success;
}

//Scan, but only so far
- (NSRange)cmr_scanCharactersInSet:(NSCharacterSet *)chars maxLength:(NSUInteger)maxLength intoString:(NSString **)outString
{
  NSRange range = [self cmr_rangeFromScanLocation];
  range.length = MIN(range.length, maxLength);

  NSUInteger len;
  for (len = 0; len < range.length; ++len) {
    if (![chars characterIsMember:[self.string characterAtIndex:(range.location + len)]]) {
      break;
    }
  }

  NSRange charRange = NSMakeRange(range.location, len);
  if (outString) {
    *outString = [self.string substringWithRange:charRange];
  }

  self.scanLocation = charRange.location + charRange.length;

  return charRange;
}

//Hex characters
static NSCharacterSet *CMRHexCharacters()
{
  static NSCharacterSet *hexChars;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    hexChars = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFabcdef"];
  });
  return hexChars;
}

//We know we've got hex already, so assume this works
static NSUInteger CMRParseHex(NSString *str, BOOL repeated)
{
  unsigned ans = 0;
  if (repeated) {
    str = [NSString stringWithFormat:@"%@%@", str, str];
  }
  NSScanner *scanner = [NSScanner scannerWithString:str];
  [scanner scanHexInt:&ans];
  return ans;
}

//Scan FFF or FFFFFF, doesn't reset scan location on failure
- (BOOL)cmr_scanHexTriple:(UIColor **)color
{
  NSString *hex = nil;
  NSRange range = [self cmr_scanCharactersInSet:CMRHexCharacters() maxLength:6 intoString:&hex];
  CGFloat red, green, blue;
  if (hex.length == 6) {
    //Parse 2 chars per component
    red   = CMRParseHex([hex substringWithRange:NSMakeRange(0, 2)], NO) / 255.0;
    green = CMRParseHex([hex substringWithRange:NSMakeRange(2, 2)], NO) / 255.0;
    blue  = CMRParseHex([hex substringWithRange:NSMakeRange(4, 2)], NO) / 255.0;
  } else if (hex.length >= 3) {
    //Parse 1 char per component, but repeat it to calculate hex value
    red   = CMRParseHex([hex substringWithRange:NSMakeRange(0, 1)], YES) / 255.0;
    green = CMRParseHex([hex substringWithRange:NSMakeRange(1, 1)], YES) / 255.0;
    blue  = CMRParseHex([hex substringWithRange:NSMakeRange(2, 1)], YES) / 255.0;
    self.scanLocation = range.location + 3;
  } else {
    return NO; //Fail
  }
  if (color) {
    *color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
  }
  return YES;
}

//Scan "transparent"
- (BOOL)cmr_scanTransparent:(UIColor **)color
{
  return [self cmr_caseInsensitiveWithCleanup:^BOOL{
    if ([self scanString:@"transparent" intoString:NULL]) {
      if (color) {
        *color = [UIColor colorWithWhite:0 alpha:0];
      }
      return YES;
    }
    return NO;
  }];
}

//Scan a float or percentage. Multiply float by `scale` if it was not a
//percentage.
- (BOOL)cmr_scanNum:(CGFloat *)value scale:(CGFloat)scale
{
  float f = 0.0;
  if ([self scanFloat:&f]) {
    if ([self scanString:@"%" intoString:NULL]) {
      f *= 0.01;
    } else {
      f *= scale;
    }
    if (value) {
      *value = f;
    }
    return YES;
  }
  return NO;
}

//Scan a triple of numbers "(10, 10, 10)". If they are not percentages, multiply
//by the corresponding `scale` component.
- (BOOL)cmr_scanFloatTriple:(CMRFloatTriple *)triple scale:(CMRFloatTriple)scale
{
  __block BOOL success = NO;
  __block CMRFloatTriple t;
  [self cmr_withSkip:[NSCharacterSet whitespaceAndNewlineCharacterSet] run:^{
    success = [self scanString:@"(" intoString:NULL]
    && [self cmr_scanNum:&(t.a) scale:scale.a]
    && [self scanString:@"," intoString:NULL]
    && [self cmr_scanNum:&(t.b) scale:scale.b]
    && [self scanString:@"," intoString:NULL]
    && [self cmr_scanNum:&(t.c) scale:scale.c]
    && [self scanString:@")" intoString:NULL];
  }];
  if (triple) {
    *triple = t;
  }
  return success;
}

//Scan a quad of numbers "(10, 10, 10, 10)". If they are not percentages,
//multiply by the corresponding `scale` component.
- (BOOL)cmr_scanFloatQuad:(CMRFloatQuad *)quad scale:(CMRFloatQuad)scale
{
  __block BOOL success = NO;
  __block CMRFloatQuad q;
  [self cmr_withSkip:[NSCharacterSet whitespaceAndNewlineCharacterSet] run:^{
    success = [self scanString:@"(" intoString:NULL]
    && [self cmr_scanNum:&(q.a) scale:scale.a]
    && [self scanString:@"," intoString:NULL]
    && [self cmr_scanNum:&(q.b) scale:scale.b]
    && [self scanString:@"," intoString:NULL]
    && [self cmr_scanNum:&(q.c) scale:scale.c]
    && [self scanString:@"," intoString:NULL]
    && [self cmr_scanNum:&(q.d) scale:scale.d]
    && [self scanString:@")" intoString:NULL];
  }];
  if (quad) {
    *quad = q;
  }
  return success;
}

@end

static inline CMRFloatTriple HSB2HSL(CGFloat hue, CGFloat saturation, CGFloat brightness)
{
  CGFloat l = (2.0 - saturation) * brightness;
  saturation *= brightness;
  CGFloat satDiv = (l <= 1.0) ? l : (2.0 - l);
  if (satDiv) {
    saturation /= satDiv;
  }
  l *= 0.5;
  CMRFloatTriple hsl = {
    hue,
    saturation,
    l
  };
  return hsl;
}

static inline CMRFloatTriple HSL2HSB(CGFloat hue, CGFloat saturation, CGFloat l)
{
  l *= 2.0;
  CGFloat s = saturation * ((l <= 1.0) ? l : (2.0 - l));
  CGFloat brightness = (l + s) * 0.5;
  if (s) {
    s = (2.0 * s) / (l + s);
  }
  CMRFloatTriple hsb = {
    hue,
    s,
    brightness
  };
  return hsb;
}

@interface UIEGradientColor ()
@property (nonatomic, strong) UIColor *color1, *color2;
@end

@implementation UIEGradientColor

- (instancetype)initWithColor1:(UIColor*)color1 color2:(UIColor*)color2
{
  if (self = [super init]) {
    _color1 = color1;
    _color2 = color2;
  }

  return self;
}

- (UIColor*)gradientWithSize:(CGSize)size
{
  return [UIColor gradientFromColor:self.color1 toColor:self.color2 withSize:size];
}

@end

