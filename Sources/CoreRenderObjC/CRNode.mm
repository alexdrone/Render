#import "CRNode.h"
#import "CRContext.h"
#import "CRCoordinator+Private.h"
#import "CRMacros.h"
#import "CRNodeBridge.h"
#import "CRNodeHierarchy.h"
#import "CRNodeLayoutSpec.h"
#import "UIView+CRNode.h"
#import "YGLayout.h"

@implementation CRAnyNode
@end

@interface CRNode ()
@property(nonatomic, readwrite) __kindof CRCoordinator *coordinator;
@property(nonatomic, readwrite) NSUInteger index;
@property(nonatomic, readwrite, nullable, weak) CRNode *parent;
@property(nonatomic, readwrite, nullable) __kindof UIView *renderedView;
/// The view initialization block.
@property(nonatomic, copy) UIView * (^viewInit)(void);
/// View configuration block.
@property(nonatomic, copy, nonnull) void (^layoutSpec)(CRNodeLayoutSpec *);
@end

void CRIllegalCoordinatorTypeException(NSString *reason) {
  @throw [NSException exceptionWithName:@"IllegalCoordinatorTypeException"
                                 reason:reason
                               userInfo:nil];
}

@implementation CRNode {
  NSMutableArray<CRNode *> *_mutableChildren;
  __weak CRNodeHierarchy *_nodeHierarchy;
  __weak CRContext *_context;
  CGSize _size;
  struct {
    unsigned int shouldInvokeDidMount : 1;
  } __attribute__((packed, aligned(1))) _flags;
}

#pragma mark - Initializer

- (instancetype)initWithType:(Class)type
             reuseIdentifier:(NSString *)reuseIdentifier
                         key:(NSString *)key
                    viewInit:(UIView * (^_Nullable)(void))viewInit
                  layoutSpec:(void (^)(CRNodeLayoutSpec<UIView *> *))layoutSpec {
  if (self = [super init]) {
    _reuseIdentifier = CR_NIL_COALESCING(reuseIdentifier, NSStringFromClass(type));
    _key = key;
    _viewType = type;
    _mutableChildren = [[NSMutableArray alloc] init];
    self.viewInit = viewInit;
    self.layoutSpec = layoutSpec;
  }
  return self;
}

#pragma mark - Convenience Initializer

+ (instancetype)nodeWithType:(Class)type
             reuseIdentifier:(NSString *)reuseIdentifier
                         key:(nullable NSString *)key
                    viewInit:(UIView * (^_Nullable)(void))viewInit
                  layoutSpec:(void (^)(CRNodeLayoutSpec<UIView *> *))layoutSpec {
  return [[CRNode alloc] initWithType:type
                      reuseIdentifier:reuseIdentifier
                                  key:key
                             viewInit:viewInit
                           layoutSpec:layoutSpec];
}

+ (instancetype)nodeWithType:(Class)type
                  layoutSpec:(void (^)(CRNodeLayoutSpec<UIView *> *))layoutSpec {
  return [[CRNode alloc] initWithType:type
                      reuseIdentifier:nil
                                  key:nil
                             viewInit:nil
                           layoutSpec:layoutSpec];
}

#pragma mark - Context

- (void)registerNodeHierarchyInContext:(CRContext *)context {
  CR_ASSERT_ON_MAIN_THREAD();
  if (!_parent) {
    _context = context;
    [self _recursivelyConfigureCoordinatorsInNodeHierarchy];
  } else
    [_parent registerNodeHierarchyInContext:context];
}

- (void)_recursivelyConfigureCoordinatorsInNodeHierarchy {
  self.coordinator.node = self;
  CR_FOREACH(child, _mutableChildren) { [child _recursivelyConfigureCoordinatorsInNodeHierarchy]; }
}

- (CRContext *)context {
  if (_context) return _context;
  return _parent.context;
}

- (CRNode *)root {
  if (!_parent) return self;
  return _parent.root;
}

- (__kindof CRCoordinator *)coordinator {
  const auto context = self.context;
  if (!context) return nil;
  if (!_coordinatorDescriptor) return _parent.coordinator;
  return [context coordinator:_coordinatorDescriptor];
}

- (CRNodeHierarchy *)nodeHierarchy {
  if (!_parent) return _nodeHierarchy;
  return _parent.nodeHierarchy;
}

- (void)setNodeHierarchy:(CRNodeHierarchy *)nodeHierarchy {
  if (!_parent) {
    _nodeHierarchy = nodeHierarchy;
    return;
  }
  [_parent setNodeHierarchy:nodeHierarchy];
}

#pragma mark - Children

- (BOOL)isNullNode {
  return false;
}

- (NSArray<CRNode *> *)children {
  return _mutableChildren;
}

- (instancetype)appendChildren:(NSArray<CRNode *> *)children {
  CR_ASSERT_ON_MAIN_THREAD();
  auto lastIndex = _mutableChildren.lastObject.index;
  CR_FOREACH(child, children) {
    if (child.isNullNode) continue;
    child.index = lastIndex++;
    child.parent = self;
    [_mutableChildren addObject:child];
  }
  return self;
}

- (instancetype)bindCoordinator:(CRCoordinatorDescriptor *)descriptor {
  CR_ASSERT_ON_MAIN_THREAD();
  _coordinatorDescriptor = descriptor;
  return self;
}

#pragma mark - Querying

- (UIView *)viewWithKey:(NSString *)key {
  if ([_key isEqualToString:key]) return _renderedView;
  CR_FOREACH(child, _mutableChildren) {
    if (const auto view = [child viewWithKey:key]) return view;
  }
  return nil;
}

- (NSArray<UIView *> *)viewsWithReuseIdentifier:(NSString *)reuseIdentifier {
  auto result = [[NSMutableArray alloc] init];
  [self _viewsWithReuseIdentifier:reuseIdentifier withArray:result];
  return result;
}

- (void)_viewsWithReuseIdentifier:(NSString *)reuseIdentifier
                        withArray:(NSMutableArray<UIView *> *)array {
  if ([_key isEqualToString:reuseIdentifier] && _renderedView) {
    [array addObject:_renderedView];
  }
  CR_FOREACH(child, _mutableChildren) {
    [child _viewsWithReuseIdentifier:reuseIdentifier withArray:array];
  }
}

#pragma mark - Layout

- (void)_constructViewWithReusableView:(nullable UIView *)reusableView {
  CR_ASSERT_ON_MAIN_THREAD();
  if (_renderedView != nil) return;

  if ([reusableView isKindOfClass:self.viewType]) {
    _renderedView = reusableView;
    _renderedView.cr_nodeBridge.node = self;
  } else {
    if (_viewInit) {
      _renderedView = _viewInit();
    } else {
      _renderedView = [[self.viewType alloc] initWithFrame:CGRectZero];
    }
    _renderedView.yoga.isEnabled = true;
    _renderedView.tag = _reuseIdentifier.hash;
    _renderedView.cr_nodeBridge.node = self;
    _flags.shouldInvokeDidMount = true;
  }
}

- (void)_configureConstrainedToSize:(CGSize)size withOptions:(CRNodeLayoutOptions)options {
  [self _constructViewWithReusableView:nil];
  [_renderedView.cr_nodeBridge storeViewSubTreeOldGeometry];
  const auto spec = [[CRNodeLayoutSpec alloc] initWithNode:self constrainedToSize:size];
  _layoutSpec(spec);

  CR_FOREACH(child, _mutableChildren) {
    [child _configureConstrainedToSize:size withOptions:options];
  }

  if (_renderedView.yoga.isEnabled && _renderedView.yoga.isLeaf &&
      _renderedView.yoga.isIncludedInLayout) {
    _renderedView.frame.size = CGSizeZero;
    [_renderedView.yoga markDirty];
  }

  if (spec.onLayoutSubviews) {
    spec.onLayoutSubviews(self, _renderedView, size);
  }
}

- (void)_computeFlexboxLayoutConstrainedToSize:(CGSize)size {
  auto rect = CGRectZero;
  rect.size = size;
  _renderedView.frame = rect;
  [_renderedView.yoga applyLayoutPreservingOrigin:NO];
  rect = _renderedView.frame;
  rect.size = _renderedView.yoga.intrinsicSize;
  _renderedView.frame = rect;
  [_renderedView.yoga applyLayoutPreservingOrigin:NO];
  rect = _renderedView.frame;
  [_renderedView cr_normalizeFrame];
}

- (void)_animateLayoutChangesIfNecessary {
  const auto animator = self.context.layoutAnimator;
  const auto view = _renderedView;
  if (!animator) return;
  [view.cr_nodeBridge storeViewSubTreeNewGeometry];
  [view.cr_nodeBridge applyViewSubTreeOldGeometry];
  [animator stopAnimation:YES];
  [animator addAnimations:^{
    [view.cr_nodeBridge applyViewSubTreeNewGeometry];
  }];
  [view.cr_nodeBridge fadeInNewlyCreatedViewsInViewSubTreeWithDelay:animator.duration];
  [animator startAnimation];
}

- (void)layoutConstrainedToSize:(CGSize)size withOptions:(CRNodeLayoutOptions)options {
  CR_ASSERT_ON_MAIN_THREAD();
  if (_parent != nil) return [_parent layoutConstrainedToSize:size withOptions:options];

  _size = size;
  auto safeAreaOffset = CGPointZero;
  if (@available(iOS 11, *)) {
    if (options & CRNodeLayoutOptionsUseSafeAreaInsets) {
      UIEdgeInsets safeArea = _renderedView.superview.safeAreaInsets;
      CGFloat heightInsets = safeArea.top + safeArea.bottom;
      CGFloat widthInsets = safeArea.left + safeArea.right;
      size.height -= heightInsets;
      size.width -= widthInsets;
      safeAreaOffset.x = safeArea.left;
      safeAreaOffset.y = safeArea.top;
    }
  }
  NSUInteger numberOfLayoutPasses = 1;
  for (NSUInteger pass = 0; pass < numberOfLayoutPasses; pass++) {
    [self _configureConstrainedToSize:size withOptions:options];
    [self _computeFlexboxLayoutConstrainedToSize:size];
  }
  auto frame = _renderedView.frame;
  frame.origin.x += safeAreaOffset.x;
  frame.origin.y += safeAreaOffset.y;
  _renderedView.frame = frame;

  if (options & CRNodeLayoutOptionsSizeContainerViewToFit) {
    auto superview = _renderedView.superview;
    UIEdgeInsets insets;
    insets.left = CR_NORMALIZE(_renderedView.yoga.marginLeft);
    insets.right = CR_NORMALIZE(_renderedView.yoga.marginRight);
    insets.top = CR_NORMALIZE(_renderedView.yoga.marginTop);
    insets.bottom = CR_NORMALIZE(_renderedView.yoga.marginBottom);
    auto rect = CGRectInset(_renderedView.bounds, -(insets.left + insets.right),
                            -(insets.top + insets.bottom));
    rect.origin = superview.frame.origin;
    superview.frame = rect;
  }
  [_renderedView cr_adjustContentSizePostLayoutRecursivelyIfNeeded];

  [self.coordinator onLayout];
  [self _animateLayoutChangesIfNecessary];
}

- (void)_reconcileNode:(CRNode *)node
                inView:(UIView *)candidateView
     constrainedToSize:(CGSize)size
        withParentView:(UIView *)parentView {
  // The candidate view is a good match for reuse.
  if ([candidateView isKindOfClass:node.viewType] && candidateView.cr_hasNode &&
      candidateView.tag == node.reuseIdentifier.hash) {
    [node _constructViewWithReusableView:candidateView];
    candidateView.cr_nodeBridge.isNewlyCreated = false;
    // The view for this node needs to be created.
  } else {
    [candidateView removeFromSuperview];
    [node _constructViewWithReusableView:nil];
    node.renderedView.cr_nodeBridge.isNewlyCreated = true;
    [parentView insertSubview:node.renderedView atIndex:node.index];
  }
  const auto view = node.renderedView;
  // Get all of the subviews.
  const auto subviews = [[NSMutableArray<UIView *> alloc] initWithCapacity:view.subviews.count];
  CR_FOREACH(subview, view.subviews) {
    if (!subview.cr_hasNode) continue;
    [subviews addObject:subview];
  }
  // Iterate children.
  CR_FOREACH(child, node.children) {
    UIView *candidateView = nil;
    auto index = 0;
    CR_FOREACH(subview, subviews) {
      if ([subview isKindOfClass:child.viewType] && subview.tag == child.reuseIdentifier.hash) {
        candidateView = subview;
        break;
      }
      index++;
    }
    // Pops the candidate view from the collection.
    if (candidateView != nil) [subviews removeObjectAtIndex:index];
    // Recursively reconcile the subnode.
    [node _reconcileNode:child
                   inView:candidateView
        constrainedToSize:size
           withParentView:node.renderedView];
  }
  // Remove all of the obsolete old views that couldn't be recycled.
  CR_FOREACH(subview, subviews) { [subview removeFromSuperview]; }
}

- (void)reconcileInView:(UIView *)view
      constrainedToSize:(CGSize)size
            withOptions:(CRNodeLayoutOptions)options {
  CR_ASSERT_ON_MAIN_THREAD();
  if (_parent != nil)
    return [_parent reconcileInView:view constrainedToSize:size withOptions:options];

  _size = size;
  const auto containerView = CR_NIL_COALESCING(view, _renderedView.superview);
  const auto bounds = CGSizeEqualToSize(size, CGSizeZero) ? containerView.bounds.size : size;
  [self _reconcileNode:self
                 inView:containerView.subviews.firstObject
      constrainedToSize:bounds
         withParentView:containerView];

  [self layoutConstrainedToSize:size withOptions:options];

  if (_flags.shouldInvokeDidMount &&
      [self.delegate respondsToSelector:@selector(rootNodeDidMount:)]) {
    _flags.shouldInvokeDidMount = false;
    [self.delegate rootNodeDidMount:self];
  }
}

- (void)setNeedsConfigure {
  const auto spec = [[CRNodeLayoutSpec alloc] initWithNode:self constrainedToSize:_size];
  _layoutSpec(spec);
}

@end

#pragma mark - nullNode

@implementation CRNullNode

+ (instancetype)nullNode {
  static CRNullNode *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (BOOL)isNullNode {
  return true;
}

@end
