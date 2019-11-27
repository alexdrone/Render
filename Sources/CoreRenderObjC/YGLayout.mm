#import "YGLayout.h"
#import "Yoga.h"

#define YG_PROPERTY(type, lowercased_name, capitalized_name)      \
  -(type)lowercased_name {                                        \
    return YGNodeStyleGet##capitalized_name(self.node);           \
  }                                                               \
                                                                  \
  -(void)set##capitalized_name : (type)lowercased_name {          \
    YGNodeStyleSet##capitalized_name(self.node, lowercased_name); \
  }

#define YG_VALUE_PROPERTY(lowercased_name, capitalized_name)      \
  -(CGFloat)lowercased_name {                                     \
    YGValue value = YGNodeStyleGet##capitalized_name(self.node);  \
    if (value.unit == YGUnitPoint) {                              \
      return value.value;                                         \
    } else {                                                      \
      return YGUndefined;                                         \
    }                                                             \
  }                                                               \
                                                                  \
  -(void)set##capitalized_name : (CGFloat)lowercased_name {       \
    YGNodeStyleSet##capitalized_name(self.node, lowercased_name); \
  }

#define YG_EDGE_PROPERTY_GETTER(lowercased_name, capitalized_name, property, edge) \
  -(CGFloat)lowercased_name {                                                      \
    return YGNodeStyleGet##property(self.node, edge);                              \
  }

#define YG_EDGE_PROPERTY_SETTER(lowercased_name, capitalized_name, property, edge) \
  -(void)set##capitalized_name : (CGFloat)lowercased_name {                        \
    YGNodeStyleSet##property(self.node, edge, lowercased_name);                    \
  }

#define YG_EDGE_PROPERTY(lowercased_name, capitalized_name, property, edge)  \
  YG_EDGE_PROPERTY_GETTER(lowercased_name, capitalized_name, property, edge) \
  YG_EDGE_PROPERTY_SETTER(lowercased_name, capitalized_name, property, edge)

#define YG_VALUE_EDGE_PROPERTY_GETTER(objc_lowercased_name, objc_capitalized_name, c_name, edge) \
  -(CGFloat)objc_lowercased_name {                                                               \
    YGValue value = YGNodeStyleGet##c_name(self.node, edge);                                     \
    if (value.unit == YGUnitPoint) {                                                             \
      return value.value;                                                                        \
    } else {                                                                                     \
      return YGUndefined;                                                                        \
    }                                                                                            \
  }

#define YG_VALUE_EDGE_PROPERTY_SETTER(objc_lowercased_name, objc_capitalized_name, c_name, edge) \
  -(void)set##objc_capitalized_name : (CGFloat)objc_lowercased_name {                            \
    YGNodeStyleSet##c_name(self.node, edge, objc_lowercased_name);                               \
  }

#define YG_VALUE_EDGE_PROPERTY(lowercased_name, capitalized_name, property, edge)  \
  YG_VALUE_EDGE_PROPERTY_GETTER(lowercased_name, capitalized_name, property, edge) \
  YG_VALUE_EDGE_PROPERTY_SETTER(lowercased_name, capitalized_name, property, edge)

#define YG_VALUE_EDGES_PROPERTIES(lowercased_name, capitalized_name)                               \
  YG_VALUE_EDGE_PROPERTY(lowercased_name##Left, capitalized_name##Left, capitalized_name,          \
                         YGEdgeLeft)                                                               \
  YG_VALUE_EDGE_PROPERTY(lowercased_name##Top, capitalized_name##Top, capitalized_name, YGEdgeTop) \
  YG_VALUE_EDGE_PROPERTY(lowercased_name##Right, capitalized_name##Right, capitalized_name,        \
                         YGEdgeRight)                                                              \
  YG_VALUE_EDGE_PROPERTY(lowercased_name##Bottom, capitalized_name##Bottom, capitalized_name,      \
                         YGEdgeBottom)                                                             \
  YG_VALUE_EDGE_PROPERTY(lowercased_name##Start, capitalized_name##Start, capitalized_name,        \
                         YGEdgeStart)                                                              \
  YG_VALUE_EDGE_PROPERTY(lowercased_name##End, capitalized_name##End, capitalized_name, YGEdgeEnd) \
  YG_VALUE_EDGE_PROPERTY(lowercased_name##Horizontal, capitalized_name##Horizontal,                \
                         capitalized_name, YGEdgeHorizontal)                                       \
  YG_VALUE_EDGE_PROPERTY(lowercased_name##Vertical, capitalized_name##Vertical, capitalized_name,  \
                         YGEdgeVertical)                                                           \
  YG_VALUE_EDGE_PROPERTY(lowercased_name, capitalized_name, capitalized_name, YGEdgeAll)

static YGConfigRef globalConfig;

@interface YGLayout ()

@property(nonatomic, weak, readonly) UIView *view;

@end

@implementation YGLayout

@synthesize isEnabled = _isEnabled;
@synthesize isIncludedInLayout = _isIncludedInLayout;
@synthesize node = _node;

+ (void)initialize {
  globalConfig = YGConfigNew();
  YGConfigSetExperimentalFeatureEnabled(globalConfig, YGExperimentalFeatureWebFlexBasis, true);
}

- (instancetype)initWithView:(UIView *)view {
  if (self = [super init]) {
    _view = view;
    _node = YGNodeNewWithConfig(globalConfig);
    YGNodeSetContext(_node, (__bridge void *)view);
    _isEnabled = false;
    _isIncludedInLayout = true;
  }
  return self;
}

- (void)dealloc {
  YGNodeFree(self.node);
}

- (void)flex {
  self.flexGrow = 1;
  self.flexShrink = 1;
}

- (BOOL)isDirty {
  return YGNodeIsDirty(self.node);
}

- (void)markDirty {
  if (self.isDirty || !self.isLeaf) {
    return;
  }
  // Yoga is not happy if we try to mark a node as "dirty" before we have set
  // the measure function. Since we already know that this is a leaf,
  // this *should* be fine. Forgive me Hack Gods.
  const YGNodeRef node = self.node;
  if (YGNodeGetMeasureFunc(node) == nil) {
    YGNodeSetMeasureFunc(node, YGMeasureView);
  }
  YGNodeMarkDirty(node);
}

- (NSUInteger)numberOfChildren {
  return YGNodeGetChildCount(self.node);
}

- (BOOL)isLeaf {
  NSAssert([NSThread isMainThread], @"This method must be called on the main thread.");
  if (self.isEnabled) {
    for (UIView *subview in self.view.subviews) {
      YGLayout *const yoga = subview.yoga;
      if (yoga.isEnabled && yoga.isIncludedInLayout) {
        return false;
      }
    }
  }
  return true;
}

#pragma mark - Style

- (YGPositionType)position {
  return YGNodeStyleGetPositionType(self.node);
}

- (void)setPosition:(YGPositionType)position {
  YGNodeStyleSetPositionType(self.node, position);
}

YG_PROPERTY(YGDirection, direction, Direction)
YG_PROPERTY(YGFlexDirection, flexDirection, FlexDirection)
YG_PROPERTY(YGJustify, justifyContent, JustifyContent)
YG_PROPERTY(YGAlign, alignContent, AlignContent)
YG_PROPERTY(YGAlign, alignItems, AlignItems)
YG_PROPERTY(YGAlign, alignSelf, AlignSelf)
YG_PROPERTY(YGWrap, flexWrap, FlexWrap)
YG_PROPERTY(YGOverflow, overflow, Overflow)
YG_PROPERTY(YGDisplay, display, Display)

YG_PROPERTY(CGFloat, flexGrow, FlexGrow)
YG_PROPERTY(CGFloat, flexShrink, FlexShrink)
YG_VALUE_PROPERTY(flexBasis, FlexBasis)

YG_VALUE_EDGE_PROPERTY(left, Left, Position, YGEdgeLeft)
YG_VALUE_EDGE_PROPERTY(top, Top, Position, YGEdgeTop)
YG_VALUE_EDGE_PROPERTY(right, Right, Position, YGEdgeRight)
YG_VALUE_EDGE_PROPERTY(bottom, Bottom, Position, YGEdgeBottom)
YG_VALUE_EDGE_PROPERTY(start, Start, Position, YGEdgeStart)
YG_VALUE_EDGE_PROPERTY(end, End, Position, YGEdgeEnd)
YG_VALUE_EDGES_PROPERTIES(margin, Margin)
YG_VALUE_EDGES_PROPERTIES(padding, Padding)

YG_EDGE_PROPERTY(borderLeftWidth, BorderLeftWidth, Border, YGEdgeLeft)
YG_EDGE_PROPERTY(borderTopWidth, BorderTopWidth, Border, YGEdgeTop)
YG_EDGE_PROPERTY(borderRightWidth, BorderRightWidth, Border, YGEdgeRight)
YG_EDGE_PROPERTY(borderBottomWidth, BorderBottomWidth, Border, YGEdgeBottom)
YG_EDGE_PROPERTY(borderStartWidth, BorderStartWidth, Border, YGEdgeStart)
YG_EDGE_PROPERTY(borderEndWidth, BorderEndWidth, Border, YGEdgeEnd)
YG_EDGE_PROPERTY(borderWidth, BorderWidth, Border, YGEdgeAll)

YG_VALUE_PROPERTY(width, Width)
YG_VALUE_PROPERTY(height, Height)
YG_VALUE_PROPERTY(minWidth, MinWidth)
YG_VALUE_PROPERTY(minHeight, MinHeight)
YG_VALUE_PROPERTY(maxWidth, MaxWidth)
YG_VALUE_PROPERTY(maxHeight, MaxHeight)
YG_PROPERTY(CGFloat, aspectRatio, AspectRatio)

#pragma mark - Layout and Sizing

- (YGDirection)resolvedDirection {
  return YGNodeLayoutGetDirection(self.node);
}

- (void)applyLayout {
  [self calculateLayoutWithSize:self.view.bounds.size];
  YGApplyLayoutToViewHierarchy(self.view, NO);
}

- (void)applyLayoutPreservingOrigin:(BOOL)preserveOrigin {
  [self calculateLayoutWithSize:self.view.bounds.size];
  YGApplyLayoutToViewHierarchy(self.view, preserveOrigin);
}

- (void)applyLayoutPreservingOrigin:(BOOL)preserveOrigin
               dimensionFlexibility:(YGDimensionFlexibility)dimensionFlexibility {
  CGSize size = self.view.bounds.size;
  if (dimensionFlexibility & YGDimensionFlexibilityFlexibleWidth) {
    size.width = YGUndefined;
  }
  if (dimensionFlexibility & YGDimensionFlexibilityFlexibleHeigth) {
    size.height = YGUndefined;
  }
  [self calculateLayoutWithSize:size];
  YGApplyLayoutToViewHierarchy(self.view, preserveOrigin);
}

- (CGSize)intrinsicSize {
  const CGSize constrainedSize = {
      .width = YGUndefined,
      .height = YGUndefined,
  };
  return [self calculateLayoutWithSize:constrainedSize];
}

#pragma mark - Private

- (CGSize)calculateLayoutWithSize:(CGSize)size {
  NSAssert([NSThread isMainThread], @"Yoga calculation must be done on main.");
  YGAttachNodesFromViewHierachy(self.view);
  const YGNodeRef node = self.node;
  YGNodeCalculateLayout(node, size.width, size.height, YGNodeStyleGetDirection(node));
  return (CGSize){
      .width = YGNodeLayoutGetWidth(node),
      .height = YGNodeLayoutGetHeight(node),
  };
}

static YGSize YGMeasureView(YGNodeRef node, float width, YGMeasureMode widthMode, float height,
                            YGMeasureMode heightMode) {
  const CGFloat constrainedWidth = (widthMode == YGMeasureModeUndefined) ? CGFLOAT_MAX : width;
  const CGFloat constrainedHeight = (heightMode == YGMeasureModeUndefined) ? CGFLOAT_MAX : height;
  UIView *view = (__bridge UIView *)YGNodeGetContext(node);
  const CGSize sizeThatFits = [view sizeThatFits:(CGSize){
                                                     .width = constrainedWidth,
                                                     .height = constrainedHeight,
                                                 }];
  return (YGSize){
      .width = static_cast<float>(
          YGSanitizeMeasurement(constrainedWidth, sizeThatFits.width, widthMode)),
      .height = static_cast<float>(
          YGSanitizeMeasurement(constrainedHeight, sizeThatFits.height, heightMode)),
  };
}

static CGFloat YGSanitizeMeasurement(CGFloat constrainedSize, CGFloat measuredSize,
                                     YGMeasureMode measureMode) {
  CGFloat result;
  if (measureMode == YGMeasureModeExactly) {
    result = constrainedSize;
  } else if (measureMode == YGMeasureModeAtMost) {
    result = MIN(constrainedSize, measuredSize);
  } else {
    result = measuredSize;
  }

  return result;
}

static BOOL YGNodeHasExactSameChildren(const YGNodeRef node, NSArray<UIView *> *subviews) {
  if (YGNodeGetChildCount(node) != subviews.count) {
    return false;
  }
  for (int i = 0; i < subviews.count; i++) {
    if (YGNodeGetChild(node, i) != subviews[i].yoga.node) {
      return false;
    }
  }
  return true;
}

static void YGAttachNodesFromViewHierachy(UIView *const view) {
  YGLayout *const yoga = view.yoga;
  const YGNodeRef node = yoga.node;
  // Only leaf nodes should have a measure function
  if (yoga.isLeaf) {
    YGRemoveAllChildren(node);
    YGNodeSetMeasureFunc(node, YGMeasureView);
  } else {
    YGNodeSetMeasureFunc(node, nil);
    NSMutableArray<UIView *> *subviewsToInclude =
        [[NSMutableArray alloc] initWithCapacity:view.subviews.count];
    for (UIView *subview in view.subviews) {
      if (subview.yoga.isIncludedInLayout) {
        [subviewsToInclude addObject:subview];
      }
    }
    if (!YGNodeHasExactSameChildren(node, subviewsToInclude)) {
      YGRemoveAllChildren(node);
      for (int i = 0; i < subviewsToInclude.count; i++) {
        YGNodeInsertChild(node, subviewsToInclude[i].yoga.node, i);
      }
    }
    for (UIView *const subview in subviewsToInclude) {
      YGAttachNodesFromViewHierachy(subview);
    }
  }
}

static void YGRemoveAllChildren(const YGNodeRef node) {
  if (node == nil) {
    return;
  }
  while (YGNodeGetChildCount(node) > 0) {
    YGNodeRemoveChild(node, YGNodeGetChild(node, YGNodeGetChildCount(node) - 1));
  }
}

static CGFloat YGRoundPixelValue(CGFloat value) {
  static CGFloat scale;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^() {
    scale = [UIScreen mainScreen].scale;
  });
  return roundf(value * scale) / scale;
}

static void YGApplyLayoutToViewHierarchy(UIView *view, BOOL preserveOrigin) {
  NSCAssert([NSThread isMainThread], @"Framesetting should only be done on the main thread.");
  const YGLayout *yoga = view.yoga;
  if (!yoga.isIncludedInLayout) {
    return;
  }
  YGNodeRef node = yoga.node;
  const CGPoint topLeft = {
      YGNodeLayoutGetLeft(node),
      YGNodeLayoutGetTop(node),
  };
  const CGPoint bottomRight = {
      topLeft.x + YGNodeLayoutGetWidth(node),
      topLeft.y + YGNodeLayoutGetHeight(node),
  };
  const CGPoint origin = preserveOrigin ? view.frame.origin : CGPointZero;
  view.frame = (CGRect){
      .origin =
          {
              .x = YGRoundPixelValue(topLeft.x + origin.x),
              .y = YGRoundPixelValue(topLeft.y + origin.y),
          },
      .size =
          {
              .width = YGRoundPixelValue(bottomRight.x) - YGRoundPixelValue(topLeft.x),
              .height = YGRoundPixelValue(bottomRight.y) - YGRoundPixelValue(topLeft.y),
          },
  };
  if (!yoga.isLeaf) {
    for (NSUInteger i = 0; i < view.subviews.count; i++) {
      YGApplyLayoutToViewHierarchy(view.subviews[i], NO);
    }
  }
}

@end

// UIView+Yoga

#import <objc/runtime.h>

static const void *kYGYogaAssociatedKey = &kYGYogaAssociatedKey;

@implementation UIView (YogaKit)

- (YGLayout *)yoga {
  YGLayout *yoga = objc_getAssociatedObject(self, kYGYogaAssociatedKey);
  if (!yoga) {
    yoga = [[YGLayout alloc] initWithView:self];
    objc_setAssociatedObject(self, kYGYogaAssociatedKey, yoga, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return yoga;
}

- (BOOL)isYogaEnabled {
  return objc_getAssociatedObject(self, kYGYogaAssociatedKey) != nil;
}

- (void)configureLayoutWithBlock:(YGLayoutConfigurationBlock)block {
  if (block) {
    block(self.yoga);
  }
}

@end

#pragma mark - Categories

@implementation UIView (YGAdditions)

- (CGFloat)cornerRadius {
  return self.layer.cornerRadius;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
  self.clipsToBounds = true;
  self.layer.cornerRadius = cornerRadius;
}

- (CGFloat)borderWidth {
  return self.layer.borderWidth;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
  self.layer.borderWidth = borderWidth;
}

- (UIColor *)borderColor {
  return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void)setBorderColor:(UIColor *)borderColor {
  self.layer.borderColor = borderColor.CGColor;
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

- (UIColor *)shadowColor {
  return [UIColor colorWithCGColor:self.layer.shadowColor];
}

- (void)setShadowColor:(UIColor *)shadowColor {
  self.layer.shadowColor = shadowColor.CGColor;
}

@end

#pragma mark - UIButton

@implementation UIButton (YGAdditions)

- (NSString *)text {
  return [self titleForState:UIControlStateNormal];
}

- (void)setText:(NSString *)text {
  [self setTitle:text forState:UIControlStateNormal];
}

- (NSString *)highlightedText {
  return [self titleForState:UIControlStateHighlighted];
}

- (void)setHighlightedText:(NSString *)highlightedText {
  [self setTitle:highlightedText forState:UIControlStateHighlighted];
}

- (NSString *)selectedText {
  return [self titleForState:UIControlStateSelected];
}

- (void)setSelectedText:(NSString *)selectedText {
  [self setTitle:selectedText forState:UIControlStateSelected];
}

- (NSString *)disabledText {
  return [self titleForState:UIControlStateDisabled];
}

- (void)setDisabledText:(NSString *)disabledText {
  [self setTitle:disabledText forState:UIControlStateDisabled];
}

- (UIColor *)textColor {
  return [self titleColorForState:UIControlStateNormal];
}

- (void)setTextColor:(UIColor *)textColor {
  [self setTitleColor:textColor forState:UIControlStateNormal];
}

- (UIColor *)highlightedTextColor {
  return [self titleColorForState:UIControlStateHighlighted];
}

- (void)setHighlightedTextColor:(UIColor *)highlightedTextColor {
  [self setTitleColor:highlightedTextColor forState:UIControlStateHighlighted];
}

- (UIColor *)selectedTextColor {
  return [self titleColorForState:UIControlStateSelected];
}

- (void)setSelectedTextColor:(UIColor *)selectedTextColor {
  [self setTitleColor:selectedTextColor forState:UIControlStateSelected];
}

- (UIColor *)disabledTextColor {
  return [self titleColorForState:UIControlStateDisabled];
}

- (void)setDisabledTextColor:(UIColor *)disabledTextColor {
  [self setTitleColor:disabledTextColor forState:UIControlStateDisabled];
}

- (UIColor *)backgroundColorImage {
  return nil;
}

- (void)setBackgroundColorImage:(UIColor *)backgroundColor {
  UIImage *image = [UIImage yg_imageWithColor:backgroundColor];
  self.backgroundImage = image;
}

- (UIImage *)backgroundImage {
  return [self backgroundImageForState:UIControlStateNormal];
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
  [self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
}

- (UIImage *)highlightedBackgroundImage {
  return [self backgroundImageForState:UIControlStateHighlighted];
}

- (void)setHighlightedBackgroundImage:(UIImage *)highlightedBackgroundImage {
  [self setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
}

- (UIImage *)selectedBackgroundImage {
  return [self backgroundImageForState:UIControlStateSelected];
}

- (void)setSelectedBackgroundImage:(UIImage *)selectedBackgroundImage {
  [self setBackgroundImage:selectedBackgroundImage forState:UIControlStateSelected];
}

- (UIImage *)disabledBackgroundImage {
  return [self backgroundImageForState:UIControlStateDisabled];
}

- (void)setDisabledBackgroundImage:(UIImage *)disabledBackgroundImage {
  [self setBackgroundImage:disabledBackgroundImage forState:UIControlStateDisabled];
}

- (UIImage *)image {
  return [self imageForState:UIControlStateNormal];
}

- (void)setImage:(UIImage *)image {
  [self setImage:image forState:UIControlStateNormal];
}

- (UIImage *)highlightedImage {
  return [self imageForState:UIControlStateHighlighted];
}

- (void)setHighlightedImage:(UIImage *)highlightedImage {
  [self setImage:highlightedImage forState:UIControlStateHighlighted];
}

- (UIImage *)selectedImage {
  return [self imageForState:UIControlStateSelected];
}

- (void)setSelectedImage:(UIImage *)selectedImage {
  [self setImage:selectedImage forState:UIControlStateSelected];
}

- (UIImage *)disabledImage {
  return [self imageForState:UIControlStateDisabled];
}

- (void)setDisabledImage:(UIImage *)disabledImage {
  [self setImage:disabledImage forState:UIControlStateDisabled];
}

@end

#pragma mark - UIImage

@implementation UIImage (YGAdditions)

+ (UIImage *)yg_imageWithColor:(UIColor *)color {
  return [self yg_imageWithColor:color size:(CGSize){1, 1}];
}

+ (UIImage *)yg_imageWithColor:(UIColor *)color size:(CGSize)size {
  CGRect rect = (CGRect){CGPointZero, size};
  UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextFillRect(context, rect);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

+ (UIImage *)yg_imageFromString:(NSString *)string
                          color:(UIColor *)color
                           font:(UIFont *)font
                           size:(CGSize)size {
  UIGraphicsBeginImageContextWithOptions(size, NO, 0);

  NSDictionary *attributes = @{NSFontAttributeName : font, NSForegroundColorAttributeName : color};
  [string drawInRect:CGRectMake(0, 0, size.width, size.height) withAttributes:attributes];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return image;
}

@end

@implementation UIViewController (YGAdditions)

- (BOOL)isModal {
  if ([self presentingViewController]) return true;
  if ([[[self navigationController] presentingViewController] presentedViewController] ==
      [self navigationController])
    return true;
  if ([[[self tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]])
    return true;
  return false;
}

@end

UIViewController *_Nullable UIGetTopmostViewController() {
  UIViewController *baseVC = UIApplication.sharedApplication.keyWindow.rootViewController;
  if ([baseVC isKindOfClass:[UINavigationController class]]) {
    return ((UINavigationController *)baseVC).visibleViewController;
  }
  if ([baseVC isKindOfClass:[UITabBarController class]]) {
    UIViewController *selectedTVC = ((UITabBarController *)baseVC).selectedViewController;
    if (selectedTVC) {
      return selectedTVC;
    }
  }
  if (baseVC.presentedViewController) {
    return baseVC.presentedViewController;
  }
  return baseVC;
}
