#import "CRUmbrellaHeader.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, CRNodeLayoutOptions) {
  CRNodeLayoutOptionsNone = 1 << 0,
  CRNodeLayoutOptionsSizeContainerViewToFit = 1 << 1
};

@class CRNode;
@class CRContext;
@class CRNodeLayoutSpec<__covariant V: UIView *>;

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

@interface CRNode<__covariant V: UIView *> : NSObject
/// The context associated with this node hierarchy.
@property(nonatomic, readonly, nullable) CRContext *context;
/// The reuse identifier for this node is its hierarchy.
/// Identifiers help Render understand which items have changed.
/// A custom *reuseIdentifier* is mandatory if the node has a custom creation closure.
@property(nonatomic, readonly) NSString *reuseIdentifier;
/// A unique key for the component/node (necessary if the associated component is stateful).
@property(nonatomic, readonly, nullable) NSString *key;
/// This component is the n-th children.
@property(nonatomic, readonly) NSUInteger index;
/// The subnodes of this node.
@property(nonatomic, readonly) NSArray<CRNode *> *children;
/// The parent node (if this is not the root node in the hierarchy).
@property(nonatomic, readonly, nullable, weak) CRNode *parent;
/// The type of the associated backing view.
@property(nonatomic, readonly) Class viewType;
/// Backing view for this node.
@property(nonatomic, readonly, nullable) V renderedView;
/// The layout delegate for this node.
@property(nonatomic, nullable, weak) id<CRNodeDelegate> delegate;

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
- (instancetype)appendChilden:(NSArray<CRNode *> *)children;

/// Register the context for the root node of this node hierarchy.
- (void)registerInContext:(CRContext *)context;

#pragma mark Render

/// Reconcile the view hierarchy with the one in the container view passed as argument.
/// @note: This method also performs layout and configuration.
- (void)reconcileInView:(UIView *)view
      constrainedToSize:(CGSize)size
            withOptions:(CRNodeLayoutOptions)options;

/// Layout and configure the views.
- (void)layoutConstrainedToSize:(CGSize)size withOptions:(CRNodeLayoutOptions)options;

#pragma mark Querying

/// Returns the view in the subtree of this node with the given @c key.
- (nullable UIView *)viewWithKey:(NSString *)key;

/// Returns all the views that have been registered with the given @c reuseIdentifier.
- (NSArray<UIView *> *)viewsWithReuseIdentifier:(NSString *)reuseIdentifier;

@end

NS_ASSUME_NONNULL_END
