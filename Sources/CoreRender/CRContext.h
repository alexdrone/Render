#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CRCoordinator;
@class CRNode;
@class CRContext;
;
@class CRContextReconciliationInfo;

NS_SWIFT_NAME(CoordinatorDescriptor)
@interface CRCoordinatorDescriptor : NSObject
/// The coordinator type.
@property(nonatomic, readonly) Class type;
/// The coordinator unique key.
@property(nonatomic, readonly) NSString *key;

- (instancetype)init NS_UNAVAILABLE;
/// Constructs a new coordinator descriptor.
- (instancetype)initWithType:(Class)type key:(NSString *)key;
@end

NS_SWIFT_NAME(ContextDelegate)
@protocol CRContextDelegate <NSObject>
/// One of the coordinator is about to invoke @c setNeedReconciliate on the root node.
- (void)context:(CRContext *)context willReconciliateHieararchy:(CRContextReconciliationInfo *)info;
/// Node/View hierarchy reconciliation has just occurred.
- (void)context:(CRContext *)context didReconciliateHieararchy:(CRContextReconciliationInfo *)info;
@end

NS_SWIFT_NAME(Context)
@interface CRContext : NSObject
/// Layout animator for the nodes registered to this context.
@property(nonatomic, nullable) UIViewPropertyAnimator *layoutAnimator;

/// Returns the coordinator (or instantiate a new one) of type @c type for the unique identifier
/// passed as argument.
/// @note: Returns @c nil if @c type is not a subclass of @c CRCoordinator (or if it's a statelss
/// coordinator).
- (__kindof CRCoordinator *)coordinator:(CRCoordinatorDescriptor *)descriptor;

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
