#import "CRContext.h"
#import "CRCoordinator.h"
#import "CRMacros.h"
#import "CRNodeBuilder+Modifiers.h"
#import "CRNodeLayoutSpec.h"
#import "YGLayout.h"

void _CRUnsafeSet(CRNodeLayoutSpec *spec, NSString *keyPath, id value) {
  const auto selector = NSSelectorFromString(keyPath);
  if (![spec.view respondsToSelector:selector]) {
    NSLog(@"warning: cannot find keyPath %@ in class %@", keyPath, spec.view.class);
  } else {
    [spec set:keyPath value:value];
  }
}

@implementation CRNodeBuilder (Modifiers)

- (instancetype)padding:(CGFloat)padding {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.padding) value:@(padding)];
  }];
}

- (instancetype)paddingInsets:(UIEdgeInsets)padding {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.paddingTop) value:@(padding.top)];
    [spec set:CR_KEYPATH(spec.view, yoga.paddingBottom) value:@(padding.bottom)];
    [spec set:CR_KEYPATH(spec.view, yoga.paddingLeft) value:@(padding.left)];
    [spec set:CR_KEYPATH(spec.view, yoga.paddingRight) value:@(padding.right)];
  }];
}

- (instancetype)margin:(CGFloat)margin {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.margin) value:@(margin)];
  }];
}

- (instancetype)marginInsets:(UIEdgeInsets)margin {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.marginTop) value:@(margin.top)];
    [spec set:CR_KEYPATH(spec.view, yoga.marginBottom) value:@(margin.bottom)];
    [spec set:CR_KEYPATH(spec.view, yoga.marginLeft) value:@(margin.left)];
    [spec set:CR_KEYPATH(spec.view, yoga.marginRight) value:@(margin.right)];
  }];
}

- (instancetype)border:(UIEdgeInsets)border {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.borderTopWidth) value:@(border.top)];
    [spec set:CR_KEYPATH(spec.view, yoga.borderBottomWidth) value:@(border.bottom)];
    [spec set:CR_KEYPATH(spec.view, yoga.borderLeftWidth) value:@(border.left)];
    [spec set:CR_KEYPATH(spec.view, yoga.borderRightWidth) value:@(border.right)];
  }];
}

- (instancetype)background:(UIColor *)color {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, backgroundColor) value:color];
  }];
}

- (instancetype)cornerRadius:(CGFloat)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, clipsToBounds) value:@(YES)];
    [spec set:CR_KEYPATH(spec.view, layer.cornerRadius) value:@(value)];
  }];
}

- (instancetype)clipped:(BOOL)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, clipsToBounds) value:@(value)];
  }];
}

- (instancetype)hidden:(BOOL)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, hidden) value:@(value)];
  }];
}

- (instancetype)opacity:(CGFloat)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, alpha) value:@(YES)];
  }];
}

- (instancetype)flexDirection:(YGFlexDirection)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.flexDirection) value:@(value)];
  }];
}

- (instancetype)justifyContent:(YGJustify)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.justifyContent) value:@(value)];
  }];
}

- (instancetype)alignContent:(YGAlign)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.alignContent) value:@(value)];
  }];
}

- (instancetype)alignItems:(YGAlign)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.alignItems) value:@(value)];
  }];
}

- (instancetype)alignSelf:(YGAlign)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.alignSelf) value:@(value)];
  }];
}

- (instancetype)position:(YGPositionType)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.position) value:@(value)];
  }];
}

- (instancetype)flexWrap:(YGWrap)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.flexWrap) value:@(value)];
  }];
}

- (instancetype)overflow:(YGOverflow)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.overflow) value:@(value)];
  }];
}

- (instancetype)flex {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec.view.yoga flex];
  }];
}

- (instancetype)flexGrow:(CGFloat)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.flexGrow) value:@(value)];
  }];
}

- (instancetype)flexShrink:(CGFloat)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.flexShrink) value:@(value)];
  }];
}

- (instancetype)flexBasis:(CGFloat)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.flexBasis) value:@(value)];
  }];
}

- (instancetype)width:(CGFloat)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.width) value:@(value)];
  }];
}

- (instancetype)height:(CGFloat)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.height) value:@(value)];
  }];
}

- (instancetype)minWidth:(CGFloat)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.minWidth) value:@(value)];
  }];
}

- (instancetype)minHeight:(CGFloat)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.minHeight) value:@(value)];
  }];
}

- (instancetype)maxWidth:(CGFloat)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.maxWidth) value:@(value)];
  }];
}

- (instancetype)maxHeight:(CGFloat)value {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.maxHeight) value:@(value)];
  }];
}

- (instancetype)matchHostingViewWidthWithMargin:(CGFloat)margin {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.width) value:@(spec.size.width - 2 * margin)];
  }];
}

- (instancetype)matchHostingViewHeightWithMargin:(CGFloat)margin {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, yoga.height) value:@(spec.size.height - 2 * margin)];
  }];
}

- (instancetype)userInteractionEnabled:(BOOL)userInteractionEnabled {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, userInteractionEnabled) value:@(userInteractionEnabled)];
  }];
}

- (instancetype)transform:(CGAffineTransform)transform animator:(UIViewPropertyAnimator *)animator {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, transform) value:@(transform) animator:animator];
  }];
}

/// Adds an animator for the whole view layout.
- (instancetype)layoutAnimator:(UIViewPropertyAnimator *)animator {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    spec.context.layoutAnimator = animator;
  }];
}

@end

@implementation CRNodeBuilder (UIControl)

- (instancetype)enabled:(BOOL)enabled {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    const auto getter = NSSelectorFromString(CR_UNSAFE_KEYPATH(isEnabled));
    if (![spec.view respondsToSelector:getter]) return;
    [spec set:CR_UNSAFE_KEYPATH(enabled) value:@(enabled)];
  }];
}

- (instancetype)selected:(BOOL)selected {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    const auto getter = NSSelectorFromString(CR_UNSAFE_KEYPATH(isSelected));
    if (![spec.view respondsToSelector:getter]) return;
    [spec set:CR_UNSAFE_KEYPATH(selected) value:@(selected)];
  }];
}

- (instancetype)highlighted:(BOOL)highlighted {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    const auto getter = NSSelectorFromString(CR_UNSAFE_KEYPATH(isHighlighted));
    if (![spec.view respondsToSelector:getter]) return;
    [spec set:CR_UNSAFE_KEYPATH(highlighted) value:@(highlighted)];
  }];
}
- (instancetype)setTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)events {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    const auto control = CR_DYNAMIC_CAST(UIControl, spec.view);
    if (!control) return;
    [control removeTarget:nil action:nil forControlEvents:events];
    [control addTarget:target action:action forControlEvents:events];
  }];
}

@end

@implementation CRNodeBuilder (UILabel)

- (instancetype)text:(nullable NSString *)text {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    const auto button = CR_DYNAMIC_CAST(UIButton, spec.view);
    if (button) {
      [button setTitle:text forState:UIControlStateNormal];
    } else {
      _CRUnsafeSet(spec, CR_UNSAFE_KEYPATH(text), text);
    }
  }];
}

- (instancetype)attributedText:(nullable NSAttributedString *)attributedText {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    const auto button = CR_DYNAMIC_CAST(UIButton, spec.view);
    if (button) {
      [button setAttributedTitle:attributedText forState:UIControlStateNormal];
    } else {
      _CRUnsafeSet(spec, CR_UNSAFE_KEYPATH(attributedText), attributedText);
    }
  }];
}

- (instancetype)font:(UIFont *)font {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    const auto button = CR_DYNAMIC_CAST(UIButton, spec.view);
    if (button) {
      [spec set:CR_KEYPATH(button, titleLabel.font) value:font];
    } else {
      _CRUnsafeSet(spec, CR_UNSAFE_KEYPATH(font), font);
    }
  }];
}

- (instancetype)textColor:(UIColor *)textColor {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    const auto button = CR_DYNAMIC_CAST(UIButton, spec.view);
    if (button) {
      [button setTitleColor:textColor forState:UIControlStateNormal];
    } else {
      _CRUnsafeSet(spec, CR_UNSAFE_KEYPATH(textColor), textColor);
    }
  }];
}

- (instancetype)textAlignment:(NSTextAlignment)textAlignment {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    _CRUnsafeSet(spec, CR_UNSAFE_KEYPATH(textAlignment), @(textAlignment));
  }];
}

- (instancetype)lineBreakMode:(NSLineBreakMode)lineBreakMode {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    _CRUnsafeSet(spec, CR_UNSAFE_KEYPATH(lineBreakMode), @(lineBreakMode));
  }];
}

- (instancetype)numberOfLines:(NSUInteger)numberOfLines {
  return [self withLayoutSpec:^(CRNodeLayoutSpec *spec) {
    _CRUnsafeSet(spec, CR_UNSAFE_KEYPATH(numberOfLines), @(numberOfLines));
  }];
}

@end
