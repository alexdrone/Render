/** Copyright (c) 2014-present, Facebook, Inc. */

#import "YGLayout.h"
#import "Yoga.h"

@interface YGLayout ()

@property (nonatomic, assign, readonly) YGNodeRef node;

- (instancetype)initWithView:(UIView *)view;

@end
