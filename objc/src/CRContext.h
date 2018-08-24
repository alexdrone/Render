#import "CRUmbrellaHeader.h"

NS_ASSUME_NONNULL_BEGIN

@class CRController;
@class CRStatelessController;
@class CRNode;
@class CRContext;
@class CRContextReconciliationInfo;

NS_SWIFT_NAME(ContextDelegate)
@protocol CRContextDelegate <NSObject>
/// One of the controller is about to invoke @c setNeedReconciliate on the root node.
- (void)context:(CRContext *)context willReconciliateHieararchy:(CRContextReconciliationInfo *)info;
/// Node/View hierarchy reconciliation has just occurred.
- (void)context:(CRContext *)context didReconciliateHieararchy:(CRContextReconciliationInfo *)info;
@end

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

/// Add the object as delegate for this context.
- (void)addDelegate:(id<CRContextDelegate>)delegate;

/// Remove the object as delegate (if necessary).
- (void)removeDelegate:(id<CRContextDelegate>)delegate;

@end

NS_SWIFT_NAME(ContextReconciliationInfo)
@interface CRContextReconciliationInfo : NSObject
/// Explictly inform the delegate that if the nodes are wrapped inside a @c UITableView or
/// a @c UICollectionView, this must be invalidated and its data reloaded.
@property(nonatomic, readonly) BOOL mustInvalidateLayout;
/// The keys of all of the nodes that have had a rect change during the last reconciliation.
@property(nonatomic, readonly) NSArray<NSString *> *keysForNodesWithMutatedSize;
/// Layout animator that is going to be used for the upcoming reconciliation.
@property(nonatomic, readonly, nullable) UIViewPropertyAnimator *layoutAnimator;

@end

NS_ASSUME_NONNULL_END
