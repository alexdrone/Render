#import "CRUmbrellaHeader.h"
#import "CRController+Private.h"

@interface CRNode ()
@property(nonatomic, readwrite) NSUInteger index;
@property(nonatomic, readwrite, nullable, weak) CRNode *parent;
@property(nonatomic, readwrite, nullable) __kindof UIView *renderedView;
/// The view initialization block.
@property (nonatomic, copy) UIView * (^viewInitialization)(void);
/// View configuration block.
@property (nonatomic, copy, nonnull) void (^layoutSpec)(CRNodeLayoutSpec *);
@end

void CRIllegalControllerTypeException(NSString *reason) {
  @throw [NSException exceptionWithName:@"IllegalControllerTypeException"
                                 reason:reason
                               userInfo:nil];
}

@implementation CRNode {
  NSMutableArray<CRNode *> *_mutableChildren;
  __weak CRContext *_context;
  struct {
    unsigned int shouldInvokeDidMount : 1;
  } _flags;
}

#pragma mark - Initializer

- (instancetype)initWithType:(Class)type
             reuseIdentifier:(NSString *)reuseIdentifier
                         key:(NSString *)key
          viewInitialization:(UIView *(^_Nullable)(void))viewInitialization
                  layoutSpec:(void (^)(CRNodeLayoutSpec<UIView *> *))layoutSpec {
  if (self = [super init]) {
    _reuseIdentifier = CR_NIL_COALESCING(reuseIdentifier, NSStringFromClass(type));
    _key = key;
    _viewType = type;
    _mutableChildren = [[NSMutableArray alloc] init];
    self.viewInitialization = viewInitialization;
    self.layoutSpec = layoutSpec;
  }
  return  self;
}

#pragma mark - Convenience Initializer

+ (instancetype)nodeWithType:(Class)type
             reuseIdentifier:(NSString *)reuseIdentifier
                         key:(nullable NSString *)key
          viewInitialization:(UIView *(^_Nullable)(void))viewInitialization
                  layoutSpec:(void (^)(CRNodeLayoutSpec<UIView *> *))layoutSpec {
  return [[CRNode alloc] initWithType:type
                      reuseIdentifier:reuseIdentifier
                                  key:key
                   viewInitialization:viewInitialization
                           layoutSpec:layoutSpec];
}

+ (instancetype)nodeWithType:(Class)type
                         key:(nullable NSString *)key
                  layoutSpec:(void (^)(CRNodeLayoutSpec<UIView *> *))layoutSpec {
  return [[CRNode alloc] initWithType:type
                      reuseIdentifier:nil
                                  key:key
                   viewInitialization:nil
                           layoutSpec:layoutSpec];
}

+ (instancetype)nodeWithType:(Class)type
                  layoutSpec:(void (^)(CRNodeLayoutSpec<UIView *> *))layoutSpec {
  return [[CRNode alloc] initWithType:type
                      reuseIdentifier:nil
                                  key:nil
                   viewInitialization:nil
                           layoutSpec:layoutSpec];
}

#pragma mark - Context

- (void)registerNodeHierarchyInContext:(CRContext *)context {
  CR_ASSERT_ON_MAIN_THREAD;
  if (!_parent) {
    _context = context;
    [self _recursivelyConfigureControllersInNodeHierarchy];
  }
  else [_parent registerNodeHierarchyInContext:context];
}

- (void)_recursivelyConfigureControllersInNodeHierarchy {
  self.controller.props = CR_NIL_COALESCING(self.controller.props, self.volatileProps);
  self.controller.state = CR_NIL_COALESCING(self.controller.state, self.initialState);
  self.controller.node = self;
  foreach(child, _mutableChildren) {
    [child _recursivelyConfigureControllersInNodeHierarchy];
  }
}

- (CRContext *)context {
  if (_context) return _context;
  return _parent.context;
}

- (CRNode *)root {
  if (!_parent) return self;
  return _parent.root;
}

- (__kindof CRController *)controller {
  const auto context = self.context;
  if (!context) return nil;
  if (!_controllerType)
    return _parent.controller;
  return _key != nil
    ? [context controllerOfType:_controllerType withKey:_key]
    : [context controllerOfType:_controllerType];
}

#pragma mark - Children

- (NSArray<CRNode *> *)children {
  return _mutableChildren;
}

- (instancetype)appendChildren:(NSArray<CRNode *> *)children {
  CR_ASSERT_ON_MAIN_THREAD;
  auto lastIndex = _mutableChildren.lastObject.index;
  foreach(child, children) {
    child.index = lastIndex++;
    child.parent = self;
    [_mutableChildren addObject:child];
  }
  return self;
}

- (instancetype)bindController:(Class)controllerType
                  initialState:(CRState *)state
                         props:(CRProps *)props {
  CR_ASSERT_ON_MAIN_THREAD;
  _volatileProps = props;
  _initialState = state;
  if (controllerType) {
    if([controllerType isSubclassOfClass:CRController.class]) {
      if (_key) {
        if ([controllerType isStateless])
          CRIllegalControllerTypeException(@"Nodes with key require a statefui controller.");
        _controllerType = controllerType;
      } else {
        if (![controllerType isStateless])
          CRIllegalControllerTypeException(@"Nodes without key require a stateless controller.");
        _controllerType = controllerType;
      }
    } else {
      CRIllegalControllerTypeException(@"Must be a subclass of CRController.");
    }
  }
  return self;
}

#pragma mark - Querying

- (UIView *)viewWithKey:(NSString *)key {
  if ([_key isEqualToString:key]) return _renderedView;
  foreach(child, _mutableChildren) {
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
  foreach(child, _mutableChildren) {
    [child _viewsWithReuseIdentifier:reuseIdentifier withArray:array];
  }
}

#pragma mark - Layout

- (void)_constructViewWithReusableView:(nullable UIView *)reusableView {
  CR_ASSERT_ON_MAIN_THREAD;
  if (_renderedView != nil) return;

  if ([reusableView isKindOfClass:self.viewType]) {
    _renderedView = reusableView;
    _renderedView.cr_nodeBridge.node = self;
  } else {
    _renderedView = [[self.viewType alloc] initWithFrame:CGRectZero];
    _renderedView.yoga.isEnabled = YES;
    _renderedView.tag = _reuseIdentifier.hash;
    _renderedView.cr_nodeBridge.node = self;
    _flags.shouldInvokeDidMount = YES;
  }
}

- (void)_configureConstrainedToSize:(CGSize)size
                        withOptions:(CRNodeLayoutOptions)options {
  [self _constructViewWithReusableView:nil];
  [_renderedView.cr_nodeBridge storeViewSubTreeOldGeometry];
  const auto spec = [[CRNodeLayoutSpec alloc] initWithNode:self constrainedToSize:size];
  _layoutSpec(spec);

  foreach(child, _mutableChildren) {
    [child _configureConstrainedToSize:size withOptions:options];
  }

  if (_renderedView.yoga.isEnabled &&
      _renderedView.yoga.isLeaf &&
      _renderedView.yoga.isIncludedInLayout) {
    _renderedView.frame.size = CGSizeZero;
    [_renderedView.yoga markDirty];
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
  [view.cr_nodeBridge applyViewSubTreeOldGeometry];
  [animator stopAnimation:YES];
  [animator addAnimations:^{
    [view.cr_nodeBridge applyViewSubTreeNewGeometry];
  }];
  [animator startAnimation];
  [view.cr_nodeBridge fadeInNewlyCreatedViewsInViewSubTreeWithDelay:animator.duration];
}

- (void)layoutConstrainedToSize:(CGSize)size withOptions:(CRNodeLayoutOptions)options {
  CR_ASSERT_ON_MAIN_THREAD;
  if (_parent != nil)
    return [_parent layoutConstrainedToSize:size withOptions:options];

  [self _configureConstrainedToSize:size withOptions:options];
  [self _computeFlexboxLayoutConstrainedToSize:size];
  [self _animateLayoutChangesIfNecessary];

  if (options & CRNodeLayoutOptionsSizeContainerViewToFit) {
    auto superview = _renderedView.superview;
    UIEdgeInsets insets;
    insets.left = CR_NORMALIZE(_renderedView.yoga.marginLeft);
    insets.right = CR_NORMALIZE(_renderedView.yoga.marginRight);
    insets.top = CR_NORMALIZE(_renderedView.yoga.marginTop);
    insets.bottom = CR_NORMALIZE(_renderedView.yoga.marginBottom);
    auto rect = CGRectInset(_renderedView.bounds,
                            -(insets.left + insets.right),
                            -(insets.top + insets.bottom));
    rect.origin = superview.frame.origin;
    superview.frame = rect;
  }
}

- (void)_reconcileNode:(CRNode *)node
                inView:(UIView *)candidateView
     constrainedToSize:(CGSize)size
        withParentView:(UIView *)parentView {
  // The candidate view is a good match for reuse.
  if ([candidateView isKindOfClass:node.viewType] &&
      candidateView.cr_hasNode &&
      candidateView.tag == node.reuseIdentifier.hash) {
    [node _constructViewWithReusableView:candidateView];
    candidateView.cr_nodeBridge.isNewlyCreated = NO;
  // The view for this node needs to be created.
  } else {
    [candidateView removeFromSuperview];
    [node _constructViewWithReusableView:nil];
    node.renderedView.cr_nodeBridge.isNewlyCreated = YES;
    [parentView insertSubview:node.renderedView atIndex:node.index];
  }
  const auto view = node.renderedView;
  // Get all of the subviews.
  const auto subviews = [[NSMutableArray<UIView *> alloc] initWithCapacity:view.subviews.count];
  foreach(subview, view.subviews) {
    if (!subview.cr_hasNode) continue;
    [subviews addObject:subview];
  }
  // Iterate children.
  foreach(child, node.children) {
    UIView *candidateView = nil;
    auto index = 0;
    foreach(subview, subviews) {
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
  foreach(subview, subviews) {
    [subview removeFromSuperview];
  }
}

- (void)reconcileInView:(UIView *)view
      constrainedToSize:(CGSize)size
            withOptions:(CRNodeLayoutOptions)options {
  CR_ASSERT_ON_MAIN_THREAD;
  if (_parent != nil)
    return [_parent reconcileInView:view constrainedToSize:size withOptions:options];

  const auto containerView = CR_NIL_COALESCING(view, _renderedView.superview);
  const auto bounds = CGSizeEqualToSize(size, CGSizeZero) ? containerView.bounds.size : size;
  [self _reconcileNode:self
                inView:containerView.subviews.firstObject
     constrainedToSize:bounds
      withParentView:containerView];
  
  [self layoutConstrainedToSize:size withOptions:options];

  if (_flags.shouldInvokeDidMount &&
      [self.delegate respondsToSelector:@selector(rootNodeDidMount:)]) {
    _flags.shouldInvokeDidMount = NO;
    [self.delegate rootNodeDidMount:self];
  }
}

- (void)setNeedsReconcile {
  CR_ASSERT_ON_MAIN_THREAD;
  if (_parent != nil)
    return [_parent setNeedsReconcile];

  [self reconcileInView:nil constrainedToSize:CGSizeZero withOptions:CRNodeLayoutOptionsNone];
}

@end

