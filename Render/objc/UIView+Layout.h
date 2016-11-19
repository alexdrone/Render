/**
 * Copyright (c) 2014-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <UIKit/UIKit.h>
#import "Layout.h"

@interface UIView (CSSLayout)

@property (nonatomic, readwrite, assign, setter=css_setUsesFlexbox:) BOOL css_usesFlexbox;

@property (nonatomic, readwrite, assign) CSSDirection css_direction;
@property (nonatomic, readwrite, assign) CSSFlexDirection css_flexDirection;
@property (nonatomic, readwrite, assign) CSSJustify css_justifyContent;
@property (nonatomic, readwrite, assign) CSSAlign css_alignContent;
@property (nonatomic, readwrite, assign) CSSAlign css_alignItems;
@property (nonatomic, readwrite, assign) CSSAlign css_alignSelf;
@property (nonatomic, readwrite, assign) CSSPositionType css_positionType;
@property (nonatomic, readwrite, assign) CSSWrapType css_flexWrap;
@property (nonatomic, readwrite, assign) CGFloat css_flexGrow;
@property (nonatomic, readwrite, assign) CGFloat css_flexShrink;
@property (nonatomic, readwrite, assign) CGFloat css_flexBasis;
@property (nonatomic, readwrite, assign) CGFloat css_width;
@property (nonatomic, readwrite, assign) CGFloat css_height;
@property (nonatomic, readwrite, assign) CGFloat css_minWidth;
@property (nonatomic, readwrite, assign) CGFloat css_minHeight;
@property (nonatomic, readwrite, assign) CGFloat css_maxWidth;
@property (nonatomic, readwrite, assign) CGFloat css_maxHeight;

- (void)css_setPosition:(CGFloat)position forEdge:(CSSEdge)edge;
- (CGFloat)css_positionForEdge:(CSSEdge)edge;
- (void)css_setMargin:(CGFloat)margin forEdge:(CSSEdge)edge;
- (CGFloat)css_marginForEdge:(CSSEdge)edge;
- (void)css_setPadding:(CGFloat)padding forEdge:(CSSEdge)edge;
- (CGFloat)css_paddingForEdge:(CSSEdge)edge;

- (CSSDirection)css_resolvedDirection;
- (void)css_applyLayout;
- (CGSize)css_sizeThatFits:(CGSize)constrainedSize;


@end
