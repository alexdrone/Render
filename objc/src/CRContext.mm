#import "CRUmbrellaHeader.h"
#import "CRController+Private.h"

@implementation CRContext {
  // The controllers identity map.
  NSMutableDictionary<NSString*, NSMutableDictionary<NSString*, CRController*>*> *_controllers;
}

- (instancetype)init {
  if (self = [super init]) {
    _controllers = @{}.mutableCopy;
  }
  return self;
}

- (__kindof CRController*)controllerOfType:(Class)type withKey:(NSString *)key {
  CR_ASSERT_ON_MAIN_THREAD;
  if (![type isSubclassOfClass:CRController.self]) return nil;
  const auto container = [self containerForType:type];
  if (const auto controller = container[key]) return controller;
  const auto controller = [[CRController alloc] initWithKey:key];
  container[key] = controller;
  return controller;
}

- (__kindof CRStatelessController *)controllerOfType:(Class)type {
  CR_ASSERT_ON_MAIN_THREAD;
  if (![type isStateless]) return nil;
  return [self controllerOfType:type withKey:CRControllerStatelessKey];
}

- (NSMutableDictionary<NSString*, CRController*> *)containerForType:(Class)type {
  const auto str = NSStringFromClass(type);
  if (const auto container = _controllers[str]) return container;
  const auto container = [[NSMutableDictionary<NSString*, CRController*> alloc] init];
  _controllers[str] = container;
  return container;
}

@end
