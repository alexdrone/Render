#import "CRUmbrellaHeader.h"

@implementation CRNodeLayoutSpec {
  NSMutableDictionary<NSString *, CRNodeLayoutSpecProperty *> *_properties;
}

- (void)set:(NSString *)keyPath value:(id)value {
  [self set:keyPath value:value animator:nil];
}

- (void)set:(NSString *)keyPath value:(id)value animator:(UIViewPropertyAnimator *)animator {
  CR_ASSERT_ON_MAIN_THREAD;
  const auto property = [[CRNodeLayoutSpecProperty alloc] initWithKeyPath:keyPath
                                                                    value:value
                                                                 animator:animator];
  _properties[keyPath] = property;
  [_view.cr_nodeBridge setPropertyWithKeyPath:keyPath value:value animator:animator];
}

- (instancetype)initWithNode:(CRNode*)node constrainedToSize:(CGSize)size {
  if (self = [super init]) {
    _node = node;
    _view = node.renderedView;
    _context = node.context;
    _controller = node.controller;
    _props = node.props;
    _state = _controller.state;
    _size = size;
  }
  return self;
}

- (void)restore {
  [_view.cr_nodeBridge restore];
}

@end

@implementation CRNodeLayoutSpecProperty

- (instancetype)initWithKeyPath:(NSString *)keyPath
                          value:(id)value
                       animator:(UIViewPropertyAnimator *)animator {
  if (self = [super init]) {
    _keyPath = keyPath;
    _value = value;
    _animator = animator;
  }
  return self;
}

@end
