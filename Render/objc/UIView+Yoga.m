/** Copyright (c) 2014-present, Facebook, Inc. */

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

- (void)resetYoga
{
  YGLayout *yoga = [[YGLayout alloc] initWithView:self];
  objc_setAssociatedObject(self, kYGYogaAssociatedKey, yoga, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)configureLayoutWithBlock:(YGLayoutConfigurationBlock)block
{
  if (block != nil) {
    block(self.yoga);
  }
}

@end
