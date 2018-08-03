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
/// The controller managing this node subtree.
@property (nonatomic, readonly, nullable, weak) __kindof CRController *controller;
/// The props passed down to this node.
@property (nonatomic, readonly, nullable, weak) __kindof CRProps *props;
/// The current state of the controller.
@property (nonatomic, readonly, nullable, weak) __kindof CRState *state;

/// The boundaries of this node.
@property (nonatomic, readonly) CGSize size;

- (instancetype)initWithNode:(CRNode*)node constrainedToSize:(CGSize)size;

- (void)set:(NSString *)keyPath value:(id)value;
- (void)set:(NSString *)keyPath value:(id)value animator:(nullable UIViewPropertyAnimator*)animator;

/// Restore the view to its initial state.
- (void)restore;

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
