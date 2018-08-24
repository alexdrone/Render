#import "CRUmbrellaHeader.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(LayoutSpec)
@interface CRNodeLayoutSpec<__covariant V: UIView *> : NSObject
/// Backing view for this node.
@property (nonatomic, readonly, nullable, weak) V view;
/// The associated node.
@property (nonatomic, readonly, nullable, weak) CRNode *node;
/// The context for this node hierarchy.
@property (nonatomic, readonly, nullable, weak) CRContext *context;

/// The boundaries of this node.
@property (nonatomic, readonly) CGSize size;

- (instancetype)initWithNode:(CRNode*)node constrainedToSize:(CGSize)size;

- (void)set:(NSString *)keyPath value:(id)value;
- (void)set:(NSString *)keyPath value:(id)value animator:(nullable UIViewPropertyAnimator*)animator;

/// Restore the view to its initial state.
- (void)restore;

/// Reset all of the view action targets.
/// @note: Applicate to @c UIControl views only.
- (void)resetAllTargets;

/// Returns the the first controller of type @c controllerType in the current subtree.
- (nullable __kindof CRController *)controllerOfType:(Class)controllerType;

@end

NS_SWIFT_NAME(LayoutSpecProperty)
@interface CRNodeLayoutSpecProperty : NSObject
/// The target keyPath in the node view.
@property (nonatomic, readonly) NSString *keyPath;
/// The new value for this property.
@property (nonatomic, readonly) id value;
/// Optional property animator.
@property (nonatomic, readonly, nullable) UIViewPropertyAnimator *animator;

- (instancetype)initWithKeyPath:(NSString *)keyPath
                          value:(id)value
                       animator:(UIViewPropertyAnimator *)animator;

@end

NS_ASSUME_NONNULL_END
