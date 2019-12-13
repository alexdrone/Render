#import "CRContext.h"
#import "CRCoordinator+Private.h"
#import "CRMacros.h"
#import "CRNode.h"

#pragma mark - CRCoordinatorDescriptor

@implementation CRCoordinatorDescriptor

- (instancetype)initWithType:(Class)type key:(NSString *)key {
  if (self = [super init]) {
    _type = type;
    _key = key;
  }
  return self;
}

- (BOOL)isEqual:(id)object {
  if (object == nil) return;
  if (![object isKindOfClass:CRCoordinatorDescriptor.class]) return;
  const auto rhs = CR_DYNAMIC_CAST(CRCoordinatorDescriptor, object);
  return [rhs.type isEqual:self.type] && [rhs.key isEqualToString:self.key];
}

@end

#pragma mark - CRContext

@implementation CRContext {
  NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, CRCoordinator *> *>
      *_coordinators;
  NSPointerArray *_delegates;
  NSMutableArray *_coordinatorPath;
}

- (instancetype)init {
  if (self = [super init]) {
    _coordinators = @{}.mutableCopy;
    _delegates = [NSPointerArray weakObjectsPointerArray];
    _coordinatorPath = @[].mutableCopy;
  }
  return self;
}

- (__kindof CRCoordinator *)coordinator:(CRCoordinatorDescriptor *)desc {
  CR_ASSERT_ON_MAIN_THREAD();
  if (![desc.type isSubclassOfClass:CRCoordinator.self]) return nil;
  const auto container = [self _containerForType:desc.type];
  if (const auto coordinator = container[desc.key]) {
    return coordinator;
  }
  const auto coordinator = CR_DYNAMIC_CAST(CRCoordinator, [[desc.type alloc] initWithKey:desc.key]);
  coordinator.key = desc.key;
  coordinator.context = self;
  container[desc.key] = coordinator;
  return coordinator;
}

- (NSMutableDictionary<NSString *, CRCoordinator *> *)_containerForType:(Class)type {
  const auto str = NSStringFromClass(type);
  if (const auto container = _coordinators[str]) return container;
  const auto container = [[NSMutableDictionary<NSString *, CRCoordinator *> alloc] init];
  _coordinators[str] = container;
  return container;
}

- (void)addDelegate:(id<CRContextDelegate>)delegate {
  CR_ASSERT_ON_MAIN_THREAD();
  [_delegates compact];
  for (NSUInteger i = 0; i < _delegates.count; i++)
    if ([_delegates pointerAtIndex:i] == (__bridge void *)(delegate)) return;
  [_delegates addPointer:(__bridge void *)delegate];
}

- (void)removeDelegate:(id<CRContextDelegate>)delegate {
  CR_ASSERT_ON_MAIN_THREAD();
  [_delegates compact];
  NSUInteger removeIdx = NSNotFound;
  for (NSUInteger i = 0; i < _delegates.count; i++)
    if ([_delegates pointerAtIndex:i] == (__bridge void *)(delegate)) {
      removeIdx = i;
      break;
    }
  if (removeIdx != NSNotFound) [_delegates removePointerAtIndex:removeIdx];
}

- (NSString *)makeCoordinatorKey:(NSString *)key {
  return
      [NSString stringWithFormat:@"%@/%@", [_coordinatorPath componentsJoinedByString:@"/"], key];
}

- (void)pushCoordinatorContext:(NSString *)key {
  CR_ASSERT_ON_MAIN_THREAD();
  [_coordinatorPath addObject:key];
}

- (void)popCoordinatorContext {
  CR_ASSERT_ON_MAIN_THREAD();
  [_coordinatorPath removeLastObject];
}

@end
