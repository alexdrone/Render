#import "CRUmbrellaHeader.h"

@implementation CRNodeBridge {
  /// The previous rect for the associated view.
  CGRect _oldGeometry;
  /// The new rect for the associated view.
  CGRect _newGeometry;
  /// The alpha computed after the last render pass.
  CGFloat _targetAlpha;
  /// The initial property values for the associated view.
  NSMutableDictionary<NSString *, id> *_initialPropertyValues;
}

- (instancetype)initWithView:(UIView *)view {
  if (self = [super init]) {
    _view = view;
    _initialPropertyValues = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)storeViewSubTreeOldGeometry {
  if (!_view.cr_hasNode) return;
  _oldGeometry = _view.frame;

  foreach(subview, _view.subviews) {
    if (!subview.cr_hasNode) continue;
    [subview.cr_nodeBridge storeViewSubTreeOldGeometry];
  }
}

- (void)applyViewSubTreeOldGeometry {
  CR_ASSERT_ON_MAIN_THREAD;
  if (!_view.cr_hasNode) return;
  if (!(_isNewlyCreated && CGRectEqualToRect(_oldGeometry, CGRectZero))) {
    _view.alpha = 0;
  } else {
    _view.frame = _oldGeometry;
    foreach(subview, _view.subviews) {
      if (!subview.cr_hasNode) continue;
      [subview.cr_nodeBridge applyViewSubTreeOldGeometry];
    }
  }
}

- (void)storeViewSubTreeNewGeometry {
  if (!_view.cr_hasNode) return;
  _newGeometry = _view.frame;
  _targetAlpha = _view.alpha;

  foreach(subview, _view.subviews) {
    if (!subview.cr_hasNode) continue;
    [subview.cr_nodeBridge storeViewSubTreeNewGeometry];
  }
}

- (void)applyViewSubTreeNewGeometry {
  CR_ASSERT_ON_MAIN_THREAD;
  if (!_view.cr_hasNode) return;
  _view.frame = _newGeometry;
  foreach(subview, _view.subviews) {
    if (!subview.cr_hasNode) continue;
    [subview.cr_nodeBridge applyViewSubTreeNewGeometry];
  }
}

- (void)fadeInNewlyCreatedViewsInViewSubTreeWithDelay:(NSTimeInterval)delay {
  CR_ASSERT_ON_MAIN_THREAD;
  static const auto duration = 0.16;
  const auto options = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut;

  CR_WEAKIFY(self);
  [UIView animateWithDuration:duration delay:delay options:options animations:^{
    CR_STRONGIFY_AND_RETURN_IF_NIL(self);
    [self _restoreAlphaRecursively];
  } completion:nil];
}

- (void)_restoreAlphaRecursively {
  if (!_view.cr_hasNode) return;
  if (fabs(_view.alpha - _targetAlpha) > FLT_EPSILON) _view.alpha = _targetAlpha;
  foreach(subview, _view.subviews) {
    [subview.cr_nodeBridge _restoreAlphaRecursively];
  }
}

- (void)setPropertyWithKeyPath:(NSString *)keyPath
                         value:(id)value
                      animator:(UIViewPropertyAnimator *)animator {
  CR_ASSERT_ON_MAIN_THREAD;
  if (!_view.cr_hasNode) return;

  const id currentValue = [_view valueForKeyPath:keyPath];
  if (!_initialPropertyValues[keyPath]) {
    _initialPropertyValues[keyPath] = currentValue;
  }
  if (![currentValue isEqual:value]) {
    CR_WEAKIFY(self);
    if (!animator) {
      [self.view setValue:value forKeyPath:keyPath];
    } else {
      [animator addAnimations:^{
        CR_STRONGIFY_AND_RETURN_IF_NIL(self);
        [self.view setValue:value forKeyPath:keyPath];
      }];
    }
  }
}

- (void)restore {
  foreach(keyPath, _initialPropertyValues) {
    const id value = _initialPropertyValues[keyPath];
    [self setPropertyWithKeyPath:keyPath value:value animator:nil];
  }
}

@end
