#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "CRNode.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(OpaqueNodeBuilder)
@interface CROpaqueNodeBuilder : NSObject
/// Optional reuse identifier.
/// @note: This is required if the node has a custom @c viewInit.
- (instancetype)withReuseIdentifier:(NSString *)reuseIdentifier;
/// Unique node key (required for stateful components).
/// @note: Internal only - Use the @c Component class to bind a node to a coordinator.
- (instancetype)_withCoordinatorKey:(NSString *)key;
/// The coordinator assigned to this node.
/// @note: Internal only - Use the @c Component class to bind a node to a coordinator.
- (instancetype)_withCoordinator:(CRCoordinator *)coordinator;
/// The coordinator type assigned to this node.
/// @note: Internal only - Use the @c Component class to bind a node to a coordinator.
- (instancetype)_withCoordinatorDescriptor:(CRCoordinatorDescriptor *)descriptor;
/// Defines the node configuration and layout.
- (instancetype)withLayoutSpec:(void (^)(CRNodeLayoutSpec<UIView *> *))layoutSpec;
/// Build the concrete node.
- (CRNode *)build;
@end

NS_SWIFT_NAME(NullNodeBuilder)
@interface CRNullNodeBuilder : CROpaqueNodeBuilder
/// Build the concrete node.
- (CRNullNode *)build;
@end

NS_SWIFT_NAME(NodeBuilder)
@interface CRNodeBuilder<__covariant V : UIView *> : CROpaqueNodeBuilder
- (instancetype)init NS_UNAVAILABLE;
/// The view type of the desired @c CRNode.
- (instancetype)initWithType:(Class)type;
/// Custom view initialization code.
- (instancetype)withViewInit:(UIView * (^)(NSString *))viewInit;
/// Defines the node configuration and layout.
- (instancetype)withLayoutSpec:(void (^)(CRNodeLayoutSpec<V> *))layoutSpec;
/// Assign the node children.
- (instancetype)withChildren:(NSArray *)children;
/// Add a child to the node children list.
- (instancetype)addChild:(CRNode *)node;
/// Build the concrete node.
- (CRNode<V> *)build;
@end

static CRNodeBuilder *CRBuildLeaf(Class type,
                                  void(NS_NOESCAPE ^ configure)(CRNodeBuilder *builder));

static CRNodeBuilder *CRBuild(Class type, void(NS_NOESCAPE ^ configure)(CRNodeBuilder *builder),
                              NSArray<CRNodeBuilder *> *children);

NS_ASSUME_NONNULL_END
