#import <Cocoa/Cocoa.h>

#pragma mark - Geometry

typedef struct UIEdgeInsets {
  CGFloat top, left, bottom, right;
} UIEdgeInsets;

static const UIEdgeInsets UIEdgeInsetsZero = { 0.0, 0.0, 0.0, 0.0 };

static inline UIEdgeInsets UIEdgeInsetsMake(CGFloat top,
                                            CGFloat left,
                                            CGFloat bottom,
                                            CGFloat right) {
  UIEdgeInsets insets = {top, left, bottom, right};
  return insets;
}

static inline CGRect UIEdgeInsetsInsetRect(CGRect rect, UIEdgeInsets insets) {
  rect.origin.x += insets.left;
  rect.origin.y += insets.top;
  rect.size.width -= (insets.left + insets.right);
  rect.size.height -= (insets.top  + insets.bottom);
  return rect;
}

static inline BOOL UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsets insets1, UIEdgeInsets insets2) {
  return insets1.left == insets2.left
    && insets1.top == insets2.top
    && insets1.right == insets2.right
    && insets1.bottom == insets2.bottom;
}

extern const UIEdgeInsets UIEdgeInsetsZero;

static inline CGPoint CGPointConstrainToRect(CGPoint point, CGRect rect) {
  return CGPointMake(MAX(rect.origin.x,
                     MIN((rect.origin.x + rect.size.width), point.x)),
                     MAX(rect.origin.y,
                     MIN((rect.origin.y + rect.size.height), point.y)));
}
