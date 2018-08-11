#import "CRUmbrellaHeader.h"

NS_ASSUME_NONNULL_BEGIN

@class CRController;
@class CRStatelessController;
@class CRNode;

NS_SWIFT_NAME(Context)
@interface CRContext : NSObject
/// Layout animator for the nodes registered to this context.
@property (nonatomic, nullable) UIViewPropertyAnimator *layoutAnimator;

/// Returns the controller (or instantiate a new one) of type @c type for the unique identifier
/// passed as argument.
/// @note: Returns @c nil if @c type is not a subclass of @c CRController (or if it's a statelss
/// controller).
- (nullable __kindof CRController*)controllerOfType:(Class)type withKey:(NSString *)key;

/// Returns the controller (or instantiate a new one) of type @c type.
/// @note: Returns @c nil if @c type is not a subclass of @c CRStatelessController.
- (nullable __kindof CRStatelessController*)controllerOfType:(Class)type;

/// Build a new node hiearchy in this context.
/// @note: This is analogous to call @c registerNodeHierarchyInContext: on the root node.
- (CRNode *)buildNodeHiearchy:(__attribute__((noescape)) CRNode *(^)(void))nodeHierarchy;

@end

NS_ASSUME_NONNULL_END
