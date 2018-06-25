#import "CRUmbrellaHeader.h"

NS_ASSUME_NONNULL_BEGIN

@class CRNode;

@interface CRNodeBridge : NSObject
/// Whether the view has been created at the last render pass.
@property (nonatomic) BOOL isNewlyCreated;
/// The node associated to this view.
@property (nonatomic, nullable, weak) CRNode *node;
/// The bridged view.
@property (nonatomic, nullable, weak) UIView *view;
/// Layout animator for this subtree.
@property (nonatomic, nullable) UIViewPropertyAnimator *layoutAnimator;

- (instancetype)initWithView:(UIView*)view;

/// Stores the current (now considered old in the current run-loop) geometry for the associated
/// view and all of its subviews recursively.
- (void)storeViewSubTreeOldGeometry;
/// Applies the stored old geometry to this view subtree.
- (void)applyViewSubTreeOldGeometry;
/// Stores the geometry for the associated view after the node has rendered at the end of the
/// current run-loop.
- (void)storeViewSubTreeNewGeometry;
/// Applies the stored new geometry to this view subtree.
- (void)applyViewSubTreeNewGeometry;
/// Transition in all of the newly created view in the view hierarchy.
- (void)fadeInNewlyCreatedViewsInViewSubTreeWithDelay:(NSTimeInterval)delay;
/// Set the property at the given keyPath.nil
- (void)setPropertyWithKeyPath:(NSString *)keyPath
                         value:(id)value
                      animator:(nullable UIViewPropertyAnimator *)animator;
/// Restore the view to its initial state.
- (void)restore;

@end

NS_ASSUME_NONNULL_END
