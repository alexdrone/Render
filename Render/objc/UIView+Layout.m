/**
 * Copyright (c) 2014-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "UIView+Layout.h"
#import <objc/runtime.h>

@interface CSSNodeBridge : NSObject
@property (nonatomic, assign, readonly) CSSNodeRef cnode;
@end

@implementation CSSNodeBridge
- (instancetype)init {
  if ([super init]) {
    _cnode = CSSNodeNew();
  }

  return self;
}

- (void)dealloc {
  CSSNodeFree(_cnode);
}

@end

@implementation UIView (CSSLayout)

- (BOOL)css_usesFlexbox {
  NSNumber *usesFlexbox = objc_getAssociatedObject(self, @selector(css_usesFlexbox));
  return [usesFlexbox boolValue];
}


#pragma mark - Setters

- (void)css_setUsesFlexbox:(BOOL)enabled {
  objc_setAssociatedObject(
    self,
    @selector(css_usesFlexbox),
    @(enabled),
    OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setCss_direction:(CSSDirection)direction {
  CSSNodeStyleSetDirection([self cssNode], direction);
}

- (CSSDirection)css_direction {
  return CSSNodeStyleGetDirection([self cssNode]);
}

- (void)setCss_flexDirection:(CSSFlexDirection)flexDirection {
  CSSNodeStyleSetFlexDirection([self cssNode], flexDirection);
}

- (CSSFlexDirection)css_flexDirection {
  return CSSNodeStyleGetFlexDirection([self cssNode]);
}

- (void)setCss_justifyContent:(CSSJustify)justifyContent {
  CSSNodeStyleSetJustifyContent([self cssNode], justifyContent);
}

- (CSSJustify)css_justifyContent {
  return CSSNodeStyleGetJustifyContent([self cssNode]);
}

- (void)setCss_alignContent:(CSSAlign)alignContent {
  CSSNodeStyleSetAlignContent([self cssNode], alignContent);
}

- (CSSAlign)css_alignContent {
  return CSSNodeStyleGetAlignContent([self cssNode]);
}

- (void)setCss_alignItems:(CSSAlign)alignItems {
  CSSNodeStyleSetAlignItems([self cssNode], alignItems);
}

- (CSSAlign)css_alignItems {
  return CSSNodeStyleGetAlignItems([self cssNode]);
}

- (void)setCss_alignSelf:(CSSAlign)alignSelf {
  CSSNodeStyleSetAlignSelf([self cssNode], alignSelf);
}

- (CSSAlign)css_alignSelf {
  return CSSNodeStyleGetAlignSelf([self cssNode]);
}

- (void)setCss_positionType:(CSSPositionType)positionType {
  CSSNodeStyleSetPositionType([self cssNode], positionType);
}

- (CSSPositionType)css_positionType {
  return CSSNodeStyleGetPositionType([self cssNode]);
}

- (void)setCss_flexWrap:(CSSWrapType)flexWrap {
  CSSNodeStyleSetFlexWrap([self cssNode], flexWrap);
}

- (CSSWrapType)css_flexWrap {
  return CSSNodeStyleGetFlexWrap([self cssNode]);
}

- (void)setCss_flexGrow:(CGFloat)flexGrow {
  CSSNodeStyleSetFlexGrow([self cssNode], flexGrow);
}

- (CGFloat)css_flexGrow {
  return CSSNodeStyleGetFlexGrow([self cssNode]);
}

- (void)setCss_flexShrink:(CGFloat)flexShrink {
  CSSNodeStyleSetFlexShrink([self cssNode], flexShrink);
}

- (CGFloat)css_flexShrink {
  return CSSNodeStyleGetFlexShrink([self cssNode]);
}

- (void)setCss_flexBasis:(CGFloat)flexBasis {
  CSSNodeStyleSetFlexBasis([self cssNode], flexBasis);
}

- (CGFloat)css_flexBasis {
  return CSSNodeStyleGetFlexBasis([self cssNode]);
}

- (void)css_setPosition:(CGFloat)position forEdge:(CSSEdge)edge {
  CSSNodeStyleSetPosition([self cssNode], edge, position);
}

- (CGFloat)css_positionForEdge:(CSSEdge)edge {
  return CSSNodeStyleGetPosition([self cssNode], edge);
}

- (void)css_setMargin:(CGFloat)margin forEdge:(CSSEdge)edge {
  CSSNodeStyleSetMargin([self cssNode], edge, margin);
  if (edge != CSSEdgeAll) return;

  CSSNodeStyleSetMargin([self cssNode], CSSEdgeTop, margin);
  CSSNodeStyleSetMargin([self cssNode], CSSEdgeLeft, margin);
  CSSNodeStyleSetMargin([self cssNode], CSSEdgeRight, margin);
  CSSNodeStyleSetMargin([self cssNode], CSSEdgeBottom, margin);
}

- (CGFloat)css_marginForEdge:(CSSEdge)edge {
  return CSSNodeStyleGetMargin([self cssNode], edge);
}

- (void)css_setPadding:(CGFloat)padding forEdge:(CSSEdge)edge {
  CSSNodeStyleSetPadding([self cssNode], edge, padding);
}

- (CGFloat)css_paddingForEdge:(CSSEdge)edge {
  return CSSNodeStyleGetPadding([self cssNode], edge);
}

- (void)setCss_width:(CGFloat)width {
  CSSNodeStyleSetWidth([self cssNode], width);
}

- (CGFloat)css_width {
  return CSSNodeStyleGetWidth([self cssNode]);
}

- (void)setCss_height:(CGFloat)height {
  CSSNodeStyleSetHeight([self cssNode], height);
}

- (CGFloat)css_height {
  return CSSNodeStyleGetHeight([self cssNode]);
}

- (void)setCss_minWidth:(CGFloat)minWidth {
  CSSNodeStyleSetMinWidth([self cssNode], minWidth);
}

- (CGFloat)css_minWidth {
  return CSSNodeStyleGetMinWidth([self cssNode]);
}

- (void)setCss_minHeight:(CGFloat)minHeight {
  CSSNodeStyleSetMinHeight([self cssNode], minHeight);
}

- (CGFloat)css_minHeight {
  return CSSNodeStyleGetMinHeight([self cssNode]);
}

- (void)setCss_maxWidth:(CGFloat)maxWidth {
  CSSNodeStyleSetMaxWidth([self cssNode], maxWidth);
}

- (CGFloat)css_maxWidth {
  return CSSNodeStyleGetMaxWidth([self cssNode]);
}

- (void)setCss_maxHeight:(CGFloat)maxHeight {
  CSSNodeStyleSetMaxHeight([self cssNode], maxHeight);
}

- (CGFloat)css_maxHeight {
  return CSSNodeStyleGetMaxHeight([self cssNode]);
}

#pragma mark - Layout and Sizing

- (CSSDirection)css_resolvedDirection {
  return CSSNodeLayoutGetDirection([self cssNode]);
}

- (CGSize)css_sizeThatFits:(CGSize)constrainedSize {
  NSAssert([NSThread isMainThread], @"CSS Layout calculation must be done on main.");
  NSAssert([self css_usesFlexbox], @"CSS Layout is not enabled for this view.");

  CLKAttachNodesFromViewHierachy(self);

  const CSSNodeRef node = [self cssNode];
  CSSNodeCalculateLayout(
    node,
    constrainedSize.width,
    constrainedSize.height,
    CSSNodeStyleGetDirection(node));

  return (CGSize) {
    .width = CSSNodeLayoutGetWidth(node),
    .height = CSSNodeLayoutGetHeight(node),
  };
}

- (void)css_applyLayout {
  [self css_sizeThatFits:self.bounds.size];
  CLKApplyLayoutToViewHierarchy(self);
}

#pragma mark - Private

- (CSSNodeRef)cssNode {
  CSSNodeBridge *node = objc_getAssociatedObject(self, @selector(cssNode));
  if (!node) {
    node = [CSSNodeBridge new];
    CSSNodeSetContext(node.cnode, (__bridge void *) self);
    objc_setAssociatedObject(self, @selector(cssNode), node, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }

  return node.cnode;
}

static CSSSize CLKMeasureView(
  CSSNodeRef node,
  float width,
  CSSMeasureMode widthMode,
  float height,
  CSSMeasureMode heightMode) {
  const CGFloat constrainedWidth = (widthMode == CSSMeasureModeUndefined) ? CGFLOAT_MAX : width;
  const CGFloat constrainedHeight = (heightMode == CSSMeasureModeUndefined) ? CGFLOAT_MAX: height;

  UIView *view = (__bridge UIView*) CSSNodeGetContext(node);
  const CGSize sizeThatFits = [view sizeThatFits:(CGSize) {
    .width = constrainedWidth,
    .height = constrainedHeight,
  }];

  return (CSSSize) {
    .width = CLKSanitizeMeasurement(constrainedWidth, sizeThatFits.width, widthMode),
    .height = CLKSanitizeMeasurement(constrainedHeight, sizeThatFits.height, heightMode),
  };
}

static CGFloat CLKSanitizeMeasurement(
  CGFloat constrainedSize,
  CGFloat measuredSize,
  CSSMeasureMode measureMode) {
  CGFloat result;
  if (measureMode == CSSMeasureModeExactly) {
    result = constrainedSize;
  } else if (measureMode == CSSMeasureModeAtMost) {
    result = MIN(constrainedSize, measuredSize);
  } else {
    result = measuredSize;
  }

  return result;
}

static void CLKAttachNodesFromViewHierachy(UIView *view) {
  CSSNodeRef node = [view cssNode];
  const BOOL usesFlexbox = [view css_usesFlexbox];
  const BOOL isLeaf = !usesFlexbox || view.subviews.count == 0;

  // Only leaf nodes should have a measure function
  if (isLeaf) {
    CSSNodeSetMeasureFunc(node, CLKMeasureView);

    // Clear any children
    while (CSSNodeChildCount(node) > 0) {
      CSSNodeRemoveChild(node, CSSNodeGetChild(node, 0));
    }
  } else {
    CSSNodeSetMeasureFunc(node, NULL);

    // Add any children which were added since the last call to css_applyLayout
    for (NSUInteger i = 0; i < view.subviews.count; i++) {
      CSSNodeRef childNode = [view.subviews[i] cssNode];
      if (CSSNodeChildCount(node) < i + 1 || CSSNodeGetChild(node, i) != childNode) {
        CSSNodeInsertChild(node, childNode, i);
      }
      CLKAttachNodesFromViewHierachy(view.subviews[i]);
    }

    // Remove any children which were removed since the last call to css_applyLayout
    while (view.subviews.count < CSSNodeChildCount(node)) {
      CSSNodeRemoveChild(node, CSSNodeGetChild(node, CSSNodeChildCount(node) - 1));
    }
  }
}

static CGFloat CLKRoundPixelValue(CGFloat value) {
  static CGFloat scale;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^(){
    scale = [UIScreen mainScreen].scale;
  });

  return round(value * scale) / scale;
}

static void CLKApplyLayoutToViewHierarchy(UIView *view) {
  NSCAssert([NSThread isMainThread], @"Framesetting should only be done on the main thread.");
  CSSNodeRef node = [view cssNode];

  const CGPoint topLeft = {
    CSSNodeLayoutGetLeft(node),
    CSSNodeLayoutGetTop(node),
  };

  const CGPoint bottomRight = {
    topLeft.x + CSSNodeLayoutGetWidth(node),
    topLeft.y + CSSNodeLayoutGetHeight(node),
  };

  view.frame = (CGRect) {
    .origin = {
      .x = CLKRoundPixelValue(topLeft.x),
      .y = CLKRoundPixelValue(topLeft.y),
    },
    .size = {
      .width = CLKRoundPixelValue(bottomRight.x) - CLKRoundPixelValue(topLeft.x),
      .height = CLKRoundPixelValue(bottomRight.y) - CLKRoundPixelValue(topLeft.y),
    },
  };

  const BOOL isLeaf = ![view css_usesFlexbox] || view.subviews.count == 0;
  if (!isLeaf) {
    for (NSUInteger i = 0; i < view.subviews.count; i++) {
      CLKApplyLayoutToViewHierarchy(view.subviews[i]);
    }
  }
}

@end
