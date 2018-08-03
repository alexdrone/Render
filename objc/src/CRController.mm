#import "CRUmbrellaHeader.h"
#import "CRController+Private.h"

NSString *CRControllerStatelessKey = @"_CRControllerStatelessKey";

@implementation CRProps
@end

@implementation CRState
@end

@implementation CRController
// By default controllers are *stateful*.
// Override @c CRStatelessController for a *stateless* controller.
+ (BOOL)isStateless {
  return NO;
}

// Private constructor.
- (instancetype)initWithKey:(NSString *)key {
  if (self = [super init]) {
    _key = key;
  }
  return self;
}

- (void)onInit {

}

- (void)onMount {

}

@end

@implementation CRStatelessController

+ (BOOL)isStateless {
  return YES;
}

@end
