#import <objc/runtime.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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
+ (UIImage*)REFL_imageWithColor:(UIColor*)color;
+ (UIImage*)REFL_imageWithColor:(UIColor*)color size:(CGSize)size;
@end


NS_ASSUME_NONNULL_END


