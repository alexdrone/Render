#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CRContext;
@class CRNode;
@class CRNodeHierarchy;
@class CRCoordinatorDescriptor;
@protocol CRNodeDelegate;

NS_SWIFT_NAME(Coordinator)
@interface CRCoordinator : NSObject
/// The context associated with this coordinator.
@property(nonatomic, readonly, nullable, weak) CRContext *context;
/// The key for this coordinator.
/// If this coordinator is @c transient the value of this property is @c CRCoordinatorStatelessKey.
@property(nonatomic, readonly) NSString *key;
/// The UI node assigned to this coordinator.
@property(nonatomic, readonly, nullable, weak) CRNodeHierarchy *body;
/// The UI node assigned to this coordinator.
@property(nonatomic, readonly, nullable, weak) CRNode *node;
/// Returns the coordinator descriptor.
@property(nonatomic, readonly) CRCoordinatorDescriptor *prototype;

/// Coordinators are instantiated from @c CRContext.
- (instancetype)init;

/// Constructs a new node hierarchy and reconciles it against the currently mounted view hierarchy.
- (void)setNeedsReconcile;

/// Tells the already mounted hierarchy must be re-layout.
/// @note This is preferable to @c setNeedsReconcile whenever there's going to be no changes in
/// the view hierarchy,
- (void)setNeedsLayout;

/// Overrides this method to manually configure the view hierarchy after it has been layed out.
- (void)onLayout;

/// Convenience method used as default target-action for buttons.
- (void)onTouchUpInside:(__kindof UIView *)sender;

/// Returns the view in the subtree of this node with the given @c key.
- (nullable UIView *)viewWithKey:(NSString *)key;

/// Returns all the views that have been registered with the given @c reuseIdentifier.
- (NSArray<UIView *> *)viewsWithReuseIdentifier:(NSString *)reuseIdentifier;

@end

NS_ASSUME_NONNULL_END
