#import "CRUmbrellaHeader.h"
#import "CRController+Private.h"

@implementation CRContext {
  NSMutableDictionary<NSString*, NSMutableDictionary<NSString*, CRController*>*> *_controllers;
  NSPointerArray *_delegates;
}

- (instancetype)init {
  if (self = [super init]) {
    _controllers = @{}.mutableCopy;
    _delegates = [NSPointerArray weakObjectsPointerArray];
  }
  return self;
}

- (__kindof CRController*)controllerOfType:(Class)type withKey:(NSString *)key {
  CR_ASSERT_ON_MAIN_THREAD;
  if (![type isSubclassOfClass:CRController.self]) return nil;
  const auto container = [self _containerForType:type];
  if (const auto controller = container[key]) return controller;
  const auto controller = CR_DYNAMIC_CAST(CRController, [[type alloc] initWithKey:key]);
  controller.context = self;
  container[key] = controller;
  return controller;
}

- (__kindof CRStatelessController *)controllerOfType:(Class)type {
  CR_ASSERT_ON_MAIN_THREAD;
  if (![type isStateless]) return nil;
  return [self controllerOfType:type withKey:CRControllerStatelessKey];
}

- (NSMutableDictionary<NSString*, CRController*> *)_containerForType:(Class)type {
  const auto str = NSStringFromClass(type);
  if (const auto container = _controllers[str]) return container;
  const auto container = [[NSMutableDictionary<NSString*, CRController*> alloc] init];
  _controllers[str] = container;
  return container;
}

- (CRNode *)buildNodeHiearchy:(__attribute__((noescape)) CRNode *(^)(void))nodeHierarchy {
  const auto node = nodeHierarchy();
  [node registerNodeHierarchyInContext:self];
  return node;
}

- (void)addDelegate:(id<CRContextDelegate>)delegate {
  CR_ASSERT_ON_MAIN_THREAD;
  [_delegates compact];
  for (NSUInteger i = 0; i < _delegates.count; i++)
    if ([_delegates pointerAtIndex:i] == (__bridge void *)(delegate)) return;
  [_delegates addPointer:(__bridge void *)delegate];
}

- (void)removeDelegate:(id<CRContextDelegate>)delegate {
  CR_ASSERT_ON_MAIN_THREAD;
  [_delegates compact];
  NSUInteger removeIdx = NSNotFound;
  for (NSUInteger i = 0; i < _delegates.count; i++)
    if ([_delegates pointerAtIndex:i] == (__bridge void *)(delegate)) {
      removeIdx = i;
      break;
    }
  if (removeIdx != NSNotFound)
    [_delegates removePointerAtIndex:removeIdx];
}

@end
