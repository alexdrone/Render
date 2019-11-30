#import "CRNodeBuilder.h"
#import "CRContext.h"
#import "CRCoordinator.h"
#import "CRMacros.h"

void CRNodeBuilderException(NSString *reason) {
  @throw [NSException exceptionWithName:@"NodeBuilderException" reason:reason userInfo:nil];
}

static CRNodeBuilder *CRBuildLeaf(Class type,
                                  void(NS_NOESCAPE ^ configure)(CRNodeBuilder *builder)) {
  return CRBuild(type, configure, @[]);
}

static CRNodeBuilder *CRBuild(Class type, void(NS_NOESCAPE ^ configure)(CRNodeBuilder *builder),
                              NSArray<CRNodeBuilder *> *children) {
  const auto builder = [[CRNodeBuilder alloc] initWithType:type];
  CR_FOREACH(node, children) { [builder addChild:[node build]]; }
  configure(builder);
  return builder;
}

@implementation CRNullNodeBuilder

- (CRNullNode *)build {
  return CRNullNode.nullNode;
}

@end

@implementation CRNodeBuilder {
  Class _type;
  NSString *_reuseIdentifier;
  NSString *_key;
  UIView * (^_viewInit)(void);
  void (^_layoutSpec)(CRNodeLayoutSpec *);
  NSMutableArray<CRNode *> *_mutableChildren;
  CRCoordinatorDescriptor *_coordinatorDescriptor;
}

- (instancetype)initWithType:(Class)type {
  CR_ASSERT_ON_MAIN_THREAD();
  if (self = [super init]) {
    _type = type;
    _mutableChildren = @[].mutableCopy;
  }
  return self;
}

- (instancetype)withReuseIdentifier:(NSString *)reuseIdentifier {
  CR_ASSERT_ON_MAIN_THREAD();
  _reuseIdentifier = reuseIdentifier;
  return self;
}

- (instancetype)withKey:(NSString *)key {
  CR_ASSERT_ON_MAIN_THREAD();
  _key = key;
  return self;
}

- (instancetype)withCoordinatorDescriptor:(CRCoordinatorDescriptor *)descriptor {
  CR_ASSERT_ON_MAIN_THREAD();
  _coordinatorDescriptor = descriptor;
  return self;
}

- (instancetype)withCoordinator:(CRCoordinator *)coordinator {
  CR_ASSERT_ON_MAIN_THREAD();
  const auto descriptor =
      [[CRCoordinatorDescriptor alloc] initWithType:coordinator.class key:coordinator.key];
  return [self withCoordinatorDescriptor:descriptor];
}

- (instancetype)withViewInit:(UIView * (^)(NSString *))viewInit {
  CR_ASSERT_ON_MAIN_THREAD();
  NSString *key = _key;
  _viewInit = ^UIView *(void) { return viewInit(key); };
  return self;
}

- (instancetype)withLayoutSpec:(void (^)(CRNodeLayoutSpec *))layoutSpec {
  CR_ASSERT_ON_MAIN_THREAD();
  void (^oldBlock)(CRNodeLayoutSpec *) = [_layoutSpec copy];
  void (^newBlock)(CRNodeLayoutSpec *) = [layoutSpec copy];
  _layoutSpec = [^(CRNodeLayoutSpec *spec) {
    if (oldBlock != nil) oldBlock(spec);
    if (newBlock != nil) newBlock(spec);
  } copy];
  return self;
}

- (instancetype)withChildren:(NSArray *)children {
  CR_ASSERT_ON_MAIN_THREAD();
  _mutableChildren = children.mutableCopy;
  CR_FOREACH(child, _mutableChildren) { NSAssert([child isKindOfClass:CRNode.class], @""); }
  return self;
}

- (instancetype)addChild:(CRNode *)node {
  CR_ASSERT_ON_MAIN_THREAD();
  [_mutableChildren addObject:node];
  return self;
}

- (CRNode *)build {
  CR_ASSERT_ON_MAIN_THREAD();
  if (_viewInit && !_reuseIdentifier) {
    CRNodeBuilderException(@"The node has a custom view initializer but no reuse identifier.");
    return CRNullNode.nullNode;
  }
  const auto node = [[CRNode alloc] initWithType:_type
                                 reuseIdentifier:_reuseIdentifier
                                             key:_key
                                        viewInit:_viewInit
                                      layoutSpec:_layoutSpec];
  if (_coordinatorDescriptor) {
    [node bindCoordinator:_coordinatorDescriptor];
  }
  [node appendChildren:_mutableChildren];
  return node;
}

@end

@implementation CROpaqueNodeBuilder

- (instancetype)withReuseIdentifier:(NSString *)reuseIdentifier {
  NSAssert(NO, @"Called on abstract super class.");
}

- (instancetype)withKey:(NSString *)key {
  NSAssert(NO, @"Called on abstract super class.");
}

- (instancetype)withLayoutSpec:(void (^)(CRNodeLayoutSpec<UIView *> *))layoutSpec {
  NSAssert(NO, @"Called on abstract super class.");
}

- (instancetype)withCoordinator:(CRCoordinator *)coordinator {
  NSAssert(NO, @"Called on abstract super class.");
}

- (instancetype)withCoordinatorDescriptor:(CRCoordinatorDescriptor *)descriptor {
  NSAssert(NO, @"Called on abstract super class.");
}

- (CRNode *)build {
  NSAssert(NO, @"Called on abstract super class.");
}

@end
