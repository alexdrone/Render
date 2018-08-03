#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *CRControllerStatelessKey;

/// Represents the properties that are externally injected into the controller.
/// This may contains *arguments*, *model objects*, *delegates* or *injectable services*.
NS_SWIFT_NAME(Props)
@interface CRProps : NSObject
/// The class of the controller associated to this.
/// @note: Subclasses must override this class property.
@property(nonatomic, readonly) Class controllerType;
@end

/// Represents the internal state of a controller.
NS_SWIFT_NAME(State)
@interface CRState : NSObject
/// The unique key for this state.
@property(nonatomic, readonly) NSString *key;
@end

NS_SWIFT_NAME(Controller)
@interface CRController<__covariant P: CRProps *, __covariant S: CRState *> : NSObject
/// Whether this controller is stateful or not.
/// Transient controllers can be reused for several UI nodes at the same time and can be disposed
/// and rebuilt at any given time.
@property(class, nonatomic, readonly, getter=isStateless) BOOL stateless;
/// The key for this controller.
/// If this controller is @c transient the value of this property is @c CRControllerStatelessKey.
@property(nonatomic, readonly) NSString *key;
/// The props currently assigned to this controller.
@property(nonatomic, readwrite) P props;
/// The current controller state.
@property(nonatomic, readwrite) S state;

/// Controllers are instantiated from @c CRContext.
- (instancetype)init NS_UNAVAILABLE;
/// Called whenever the controller is constructed.
- (void)onInit;
/// The UI node  associated to this controller has just been added to the view hierarchy.
/// @note: This is similiar to @c viewDidAppear on @c UIViewController.
- (void)onMount;

@end

/// Represents a null empty state - used to model @c CRStatelessController.
NS_SWIFT_NAME(NullState)
@interface CRNullState: CRState
@end

NS_SWIFT_NAME(StatelessController)
@interface CRStatelessController<__covariant P: CRProps *> : CRController<P, CRNullState*>
@end

NS_ASSUME_NONNULL_END
