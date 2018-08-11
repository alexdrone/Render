#import "CRUmbrellaHeader.h"

@implementation CRNodeLayoutSpec {
  NSMutableDictionary<NSString *, CRNodeLayoutSpecProperty *> *_properties;
}

- (void)set:(NSString *)keyPath value:(id)value {
  [self set:keyPath value:value animator:nil];
}

- (void)set:(NSString *)keyPath value:(id)value animator:(UIViewPropertyAnimator *)animator {
  CR_ASSERT_ON_MAIN_THREAD;
  const auto property = [[CRNodeLayoutSpecProperty alloc] initWithKeyPath:keyPath
                                                                    value:value
                                                                 animator:animator];
  _properties[keyPath] = property;
  [_view.cr_nodeBridge setPropertyWithKeyPath:keyPath value:value animator:animator];
}

- (instancetype)initWithNode:(CRNode*)node constrainedToSize:(CGSize)size {
  if (self = [super init]) {
    _node = node;
    _view = node.renderedView;
    _context = node.context;
    _size = size;
  }
  return self;
}

- (__kindof CRController *)controllerOfType:(Class)controllerType {
  if (![controllerType isSubclassOfClass:CRController.class]) return nil;

  auto controller = (CRController *)nil;
  auto node = self.node;
  auto context = self.context;
  NSAssert(node, @"Called when *node* is nil.");
  NSAssert(context, @"Called when *context* is nil.");
  while (node) {
    if (node.controllerType == controllerType) {
      controller = node.controller;
      break;
    }
    node = node.parent;
  }
  return controller;
}

- (void)restore {
  [_view.cr_nodeBridge restore];
}

- (void)resetAllTargets {
  [_view cr_resetAllTargets];
}

@end

@implementation CRNodeLayoutSpecProperty

- (instancetype)initWithKeyPath:(NSString *)keyPath
                          value:(id)value
                       animator:(UIViewPropertyAnimator *)animator {
  if (self = [super init]) {
    _keyPath = keyPath;
    _value = value;
    _animator = animator;
  }
  return self;
}

@end
