#import "CRUmbrellaHeader.h"
#import "CRController+Private.h"

NSString *CRControllerStatelessKey = @"_CRControllerStatelessKey";
NSString *CRIllegalControllerTypeExceptionName = @"IllegalControllerType";

#pragma mark - Props & State

@implementation CRProps
- (Class)controllerType {
  [NSException raise:CRIllegalControllerTypeExceptionName
              format:@"Subclasses must return the desired CRController subclass."];
  return nil;
}

- (instancetype)init {
  if (self = [super init]) {
    if (![self.controllerType isSubclassOfClass:CRController.self]) {
      [NSException raise:CRIllegalControllerTypeExceptionName
                  format:@"controllerType must be a subclass of CRController."];
    }
  }
  return self;
}

@end

@implementation CRState
@end

#pragma mark - Controller

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
  // Override in subclasses.
}

- (void)onMount {
  // Override in subclasses.
}

@end

#pragma mark - StatelessController

@implementation CRStatelessController

+ (BOOL)isStateless {
  return YES;
}

@end
