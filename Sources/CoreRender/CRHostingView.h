#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "CRNode.h"

NS_ASSUME_NONNULL_BEGIN

@class CRContext;
@class CRNodeHierarchy;
@class CROpaqueNodeBuilder;

NS_SWIFT_NAME(HostingView)
@interface CRHostingView : UIView
/// The exposed node hierarchy.
@property(nonatomic, readonly) CRNodeHierarchy *body;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

/// Construct a new hosting view with the given reference context.
- (instancetype)initWithContext:(CRContext *)context
                    withOptions:(CRNodeLayoutOptions)options
                           body:(CROpaqueNodeBuilder * (^)(CRContext *))buildBody
    NS_DESIGNATED_INITIALIZER;

/// Tells the node that the node/view hierarchy must be reconciled.
- (void)setNeedsReconcile;

/// Tells the node that the node/view hierarchy must be re-layout.
/// @note This is preferable to @c setNeedsReconcile whenever there's going to be no changes in
/// the view hierarchy,
- (void)setNeedsLayout;

@end

NS_ASSUME_NONNULL_END
