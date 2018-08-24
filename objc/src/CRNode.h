#import "CRUmbrellaHeader.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(NodeLayoutOptions)
typedef NS_OPTIONS(NSUInteger, CRNodeLayoutOptions) {
  CRNodeLayoutOptionsNone = 1 << 0,
  CRNodeLayoutOptionsSizeContainerViewToFit = 1 << 1
};

@class CRNode;
@class CRContext;
@class CRNodeLayoutSpec<__covariant V: UIView *>;
@class CRState;
@class CRProps;

NS_SWIFT_NAME(NodeDelegate)
@protocol CRNodeDelegate <NSObject>
@optional
/// The root node for this hierarchy is being configured and layed out.
/// Additional custom manual layout can be defined here.
/// @note: Use @viewWithKey or @viewsWithReuseIdentifier to query the desired views in the
/// installed view hierarchy.
- (void)rootNodeDidLayout:(CRNode *)node;
/// The node @renderedView just got inserted in the view hierarchy.
- (void)rootNodeDidMount:(CRNode *)node;
@end

NS_SWIFT_NAME(ConcreteNode)
@interface CRNode<__covariant V: UIView *> : NSObject
/// The context associated with this node hierarchy.
@property(nonatomic, readonly, nullable) CRContext *context;
/// The reuse identifier for this node is its hierarchy.
/// Identifiers help Render understand which items have changed.
/// A custom *reuseIdentifier* is mandatory if the node has a custom creation closure.
@property(nonatomic, readonly) NSString *reuseIdentifier;
/// A unique key for the component/node (necessary if the associated controller is stateful).
@property(nonatomic, readonly, nullable) NSString *key;
/// This component is the n-th children.
@property(nonatomic, readonly) NSUInteger index;
/// The subnodes of this node.
@property(nonatomic, readonly) NSArray<CRNode *> *children;
/// The parent node (if this is not the root node in the hierarchy).
@property(nonatomic, readonly, nullable, weak) CRNode *parent;
/// Returns the root node for this node hierarchy.
@property(nonatomic, readonly) CRNode *root;
/// The type of the associated backing view.
@property(nonatomic, readonly) Class viewType;
/// Backing view for this node.
@property(nonatomic, readonly, nullable) V renderedView;
/// The layout delegate for this node.
@property(nonatomic, nullable, weak) id<CRNodeDelegate> delegate;
/// The type of the associated controller.
@property(nonatomic, nullable, readonly) Class controllerType;
/// Returns the associated controller.
/// @note: @c nil if this node hierarchy is not registered to any @c CRContext, or if
/// @c controllerType is @c nil.
@property(nonatomic, nullable, readonly) __kindof CRController *controller;
/// Represents the properties that are externally injected into the controller.
@property(nonatomic, nullable, readonly) __kindof CRProps *volatileProps;
/// The initial state (if the controller doesn't have one already).
@property(nonatomic, nullable, readonly) __kindof CRState *initialState;

#pragma mark Constructors

- (instancetype)initWithType:(Class)type
             reuseIdentifier:(nullable NSString *)reuseIdentifier
                         key:(nullable NSString *)key
          viewInitialization:(UIView *(^_Nullable)(void))viewInitialization
                  layoutSpec:(void (^)(CRNodeLayoutSpec<V> *))layoutSpec;

+ (instancetype)nodeWithType:(Class)type
             reuseIdentifier:(NSString *)reuseIdentifier
                         key:(nullable NSString *)key
          viewInitialization:(UIView *(^_Nullable)(void))viewInitialization
                  layoutSpec:(void (^)(CRNodeLayoutSpec<V> *))layoutSpec;

+ (instancetype)nodeWithType:(Class)type
                         key:(nullable NSString *)key
                  layoutSpec:(void (^)(CRNodeLayoutSpec<V> *))layoutSpec;

+ (instancetype)nodeWithType:(Class)type
                  layoutSpec:(void (^)(CRNodeLayoutSpec<V> *))layoutSpec;

#pragma mark Setup

/// Adds the nodes as children of this node.
- (instancetype)appendChildren:(NSArray<CRNode *> *)children;

/// Bind this node to the @c CRController class passed as argument.
- (instancetype)bindController:(Class)controllerType
                  initialState:(CRState *)state
                         props:(CRProps *)props;

/// Register the context for the root node of this node hierarchy.
- (void)registerNodeHierarchyInContext:(CRContext *)context;

#pragma mark Render

/// Reconcile the view hierarchy with the one in the container view passed as argument.
/// @note: This method also performs layout and configuration.
- (void)reconcileInView:(nullable UIView *)view
      constrainedToSize:(CGSize)size
            withOptions:(CRNodeLayoutOptions)options;

/// Layout and configure the views.
- (void)layoutConstrainedToSize:(CGSize)size withOptions:(CRNodeLayoutOptions)options;

/// Tells the node that the node/view hierarchy must be reconciled.
- (void)setNeedsReconcile;

#pragma mark Querying

/// Returns the view in the subtree of this node with the given @c key.
- (nullable UIView *)viewWithKey:(NSString *)key;

/// Returns all the views that have been registered with the given @c reuseIdentifier.
- (NSArray<UIView *> *)viewsWithReuseIdentifier:(NSString *)reuseIdentifier;

@end

NS_ASSUME_NONNULL_END
