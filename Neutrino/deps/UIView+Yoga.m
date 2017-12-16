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

void YGSet(UIView *view, NSDictionary *properties) {
  static NSString *percentageSuffix = @"_percentage";
  for (NSString *key in [properties allKeys]) {
    if ([key hasSuffix:percentageSuffix]) {
      NSString *path = [key stringByReplacingOccurrencesOfString:percentageSuffix withString:@""];
      NSNumber *value = properties[key];
      YGValue ygValue = {value.floatValue, YGUnitPercent};
      YGPercentLayout *percent = view.yoga.percent;
      if ([percent respondsToSelector:@selector(path)]) {
        [view.yoga.percent setValue:@(ygValue) forKey:path];
      }
    } else {
      NSString *keyPath = YGReplaceKeyIfNecessary(key);
      if ([view respondsToSelector: NSSelectorFromString(keyPath)]
          || [view.yoga respondsToSelector:NSSelectorFromString(key)]) {
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
