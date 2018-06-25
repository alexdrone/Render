#import "CRUmbrellaHeader.h"

NS_ASSUME_NONNULL_BEGIN

@class CRNode;
@class CRNodeBridge;

@interface UIView (CRNode)
/// Whether this view has a node currently associated to it or not.
@property (nonatomic, readonly) BOOL cr_hasNode;
/// Transient node configuration for this view.
@property (nonatomic) CRNodeBridge *cr_nodeBridge;
/// Remove all of the registered targets if this view is a subclass of *UIControl*.
- (void)cr_resetAllTargets;

- (void)cr_normalizeFrame;

@end

NS_ASSUME_NONNULL_END
