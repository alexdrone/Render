#import <objc/runtime.h>
#import "CRMacros.h"
#import "CRNode.h"
#import "CRNodeBridge.h"
#import "UIView+CRNode.h"
#import "YGLayout.h"

@implementation UIView (CRNode)
@dynamic cr_nodeBridge;

- (BOOL)cr_hasNode {
  return self.cr_nodeBridge.node != nil;
}

- (void)setCr_nodeBridge:(CRNodeBridge *)obj {
  objc_setAssociatedObject(self, @selector(cr_nodeBridge), obj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CRNodeBridge *)cr_nodeBridge {
  auto bridge =
      CR_DYNAMIC_CAST(CRNodeBridge, objc_getAssociatedObject(self, @selector(cr_nodeBridge)));
  const auto ret = CR_NIL_COALESCING(bridge, [[CRNodeBridge alloc] initWithView:self]);
  if (ret != bridge) self.cr_nodeBridge = ret;
  return ret;
}

- (void)cr_resetAllTargets {
  CR_ASSERT_ON_MAIN_THREAD();
  const auto control = CR_DYNAMIC_CAST(UIControl, self);
  CR_FOREACH(target, control.allTargets) {
    [control removeTarget:target action:nil forControlEvents:UIControlEventAllEvents];
  }
}

- (void)cr_normalizeFrame {
  auto rect = self.frame;
  rect.origin.x = CR_NORMALIZE(rect.origin.x);
  rect.origin.y = CR_NORMALIZE(rect.origin.y);
  rect.size.width = CR_NORMALIZE(rect.size.width);
  rect.size.height = CR_NORMALIZE(rect.size.height);
  self.frame = rect;
}

- (void)cr_adjustContentSizePostLayoutRecursivelyIfNeeded {
  if (!self.cr_hasNode) return;
  if ([self isKindOfClass:UIScrollView.class]) {
    [(UIScrollView *)self cr_adjustContentSizePostLayout];
  }
  CR_FOREACH(subview, self.subviews) {
    [subview cr_adjustContentSizePostLayoutRecursivelyIfNeeded];
  }
}

@end

@implementation UIScrollView (CRNode)

- (void)cr_adjustContentSizePostLayout {
  if ([self isKindOfClass:UITableView.class]) return;
  if ([self isKindOfClass:UICollectionView.class]) return;
  dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC));
  dispatch_after(time, dispatch_get_main_queue(), ^{
    CGFloat x = 0;
    CGFloat y = 0;
    CR_FOREACH(subview, self.subviews) {
      x = MAX(x, CGRectGetMaxX(subview.frame));
      y = MAX(y, CGRectGetMaxY(subview.frame));
    }
    if (self.yoga.flexDirection == YGFlexDirectionColumn ||
        self.yoga.flexDirection == YGFlexDirectionRowReverse) {
      self.contentSize = CGSizeMake(self.contentSize.width, y);
    } else {
      self.contentSize = CGSizeMake(x, self.contentSize.height);
    }
    self.scrollEnabled = true;
  });
}

@end
