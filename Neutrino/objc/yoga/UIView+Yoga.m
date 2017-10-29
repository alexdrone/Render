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

void YGSet(UIView *view, NSDictionary *properties) {
  for (NSString *key in [properties allKeys]) {
    NSString *keyPath = YGReplaceKeyIfNecessary(key);
    [view setValue:properties[key] forKeyPath:keyPath];
  }
}

static NSArray *UIKitSymbols = nil;
NSArray *YGUIKitSymbols() {
  if (UIKitSymbols == nil) UIKitSymbols = @[
      @"UIView",
      @"UILabel",
      @"UIButton",
      @"UIScrollView",
      @"UITextField",
      @"UITextView",
      @"UIImageView",
      @"UISegmentedControl",
      @"UISwitch",
      @"UIPaginationControl",
      @"UIControl"];
  return UIKitSymbols;
}
static NSArray *YGProps = nil;
NSString *YGReplaceKeyIfNecessary(NSString *key) {
  if (YGProps == nil) YGProps = @[
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
      @"maxHeight"];
  if ([YGProps containsObject:key]) {
    return [NSString stringWithFormat:@"%@.%@", @"yoga", key];
  }
  return key;
}
