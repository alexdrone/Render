#import <objc/runtime.h>
#import "CRUmbrellaHeader.h"

@implementation UIView (CRNode)
@dynamic cr_nodeBridge;

- (BOOL)cr_hasNode {
  return self.cr_nodeBridge.node != nil;
}

- (void)setCr_nodeBridge:(CRNodeBridge *)obj {
  objc_setAssociatedObject(self, @selector(cr_nodeBridge), obj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CRNodeBridge *)cr_nodeBridge {
  auto bridge = CR_DYNAMIC_CAST(CRNodeBridge,
                                objc_getAssociatedObject(self, @selector(cr_nodeBridge)));
  const auto ret = CR_NIL_COALESCING(bridge, [[CRNodeBridge alloc] initWithView:self]);
  if (ret != bridge) self.cr_nodeBridge = ret;
  return ret;
}

- (void)cr_resetAllTargets {
  CR_ASSERT_ON_MAIN_THREAD;
  const auto control = CR_DYNAMIC_CAST(UIControl, self);
  foreach(target, control.allTargets) {
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
@end
