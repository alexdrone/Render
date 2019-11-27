#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "CRNode.h"
@class CROpaqueNodeBuilder;

NS_ASSUME_NONNULL_BEGIN

@class CRContext;

NS_SWIFT_NAME(NodeHierarchy)
@interface CRNodeHierarchy : NSObject
/// The current root node.
@property(nonatomic, readonly) CRNode *root;

- (instancetype)init NS_UNAVAILABLE;

/// Instantiate a new node hierarchy.
- (instancetype)initWithContext:(CRContext *)context
           nodeHierarchyBuilder:(CROpaqueNodeBuilder * (^)(CRContext *))buildNodeHierarchy;

#pragma mark Render

/// Constructs a new node hierarchy by invoking the @c buildNodeHierarchy block and reconciles it
/// against the view passed as argument.
- (void)buildHierarchyInView:(UIView *)view
           constrainedToSize:(CGSize)size
                 withOptions:(CRNodeLayoutOptions)options;

/// See @c CRNode.reconcileInView:constrainedToSize:withOptions:.
- (void)reconcileInView:(nullable UIView *)view
      constrainedToSize:(CGSize)size
            withOptions:(CRNodeLayoutOptions)options;

/// See @c CRNode.slayoutConstrainedToSize:withOptions:.
- (void)layoutConstrainedToSize:(CGSize)size withOptions:(CRNodeLayoutOptions)options;

/// Constructs a new node hierarchy by invoking the @c buildNodeHierarchy block and reconciles it
/// against the currently mounted view hierarchy.
- (void)setNeedsReconcile;

/// Tells the node that the node/view hierarchy must be re-layout.
/// @note This is preferable to @c setNeedsReconcile whenever there's going to be no changes in
/// the view hierarchy,
- (void)setNeedsLayout;

@end

NS_ASSUME_NONNULL_END
