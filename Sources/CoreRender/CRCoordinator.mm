#import "CRContext.h"

#import "CRCoordinator+Private.h"
#import "CRMacros.h"
#import "CRNode.h"
#import "CRNodeHierarchy.h"

NSString *CRIllegalCoordinatorTypeExceptionName = @"IllegalCoordinatorType";

#pragma mark - Coordinator

@implementation CRCoordinator

- (instancetype)init {
  if (self = [super init]) {
  }
  return self;
}

- (CRNodeHierarchy *)body {
  return _node.nodeHierarchy;
}

- (CRCoordinatorDescriptor *)prototype {
  return [[CRCoordinatorDescriptor alloc] initWithType:self.class key:self.key];
}

// Private constructor.
- (instancetype)initWithKey:(NSString *)key {
  if (self = [super init]) {
    _key = key;
  }
  return self;
}

- (void)setNeedsReconcile {
  CR_ASSERT_ON_MAIN_THREAD();
  [self.body setNeedsReconcile];
}

- (void)setNeedsLayout {
  CR_ASSERT_ON_MAIN_THREAD();
  [self.body setNeedsLayout];
}

- (void)onTouchUpInside:(__kindof UIView *)sender {
  CR_ASSERT_ON_MAIN_THREAD();
}

- (void)onLayout {
  CR_ASSERT_ON_MAIN_THREAD();
}

- (UIView *)viewWithKey:(NSString *)key {
  return [self.body.root viewWithKey:key];
}

- (NSArray<UIView *> *)viewsWithReuseIdentifier:(NSString *)reuseIdentifier {
  return [self.body.root viewsWithReuseIdentifier:reuseIdentifier];
}

@end
