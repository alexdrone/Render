#import <XCTest/XCTest.h>
#import <CoreRender/CoreRender.h>

@interface CRNodeTests : XCTestCase
@property (nonatomic, weak) UILabel *testOutlet;
@end

@interface TestController : CRController<CRNullProps *, CRNullState *>
@end

@interface TestStatelessController : CRStatelessController<CRNullProps *>
@end

@implementation CRNodeTests

- (CRNode *)buildLabelNode {
  const auto node = [CRNode nodeWithType:UILabel.class
                              layoutSpec:^(CRNodeLayoutSpec<UILabel *> *spec) {
    [spec set:CR_KEYPATH(spec.view, text) value:@"test"];
    [spec set:CR_KEYPATH(spec.view, textColor) value:UIColor.redColor];
  }];
  return node;
}

- (void)assertLabelDidLayout:(UIView *)view {
  const auto label = CR_DYNAMIC_CAST(UILabel, view);
  XCTAssertNotNil(label);
  XCTAssert([label.text isEqualToString:@"test"]);
  XCTAssert([label.textColor isEqual:UIColor.redColor]);
  const auto rect = label.frame;
  XCTAssert(!CGRectEqualToRect(rect, CGRectZero));
  XCTAssert(!CGRectEqualToRect(rect, CGRectZero));
}

- (void)testTrivialLayout {
  const auto node = [self buildLabelNode];
  const auto view = [[UIView alloc] init];
  [node reconcileInView:view
      constrainedToSize:CGSizeMake(320, CR_CGFLOAT_FLEXIBLE)
            withOptions:CRNodeLayoutOptionsSizeContainerViewToFit];
  XCTAssert(view.subviews.count == 1);
  [self assertLabelDidLayout:view.subviews.firstObject];
}

- (void)testTrivialLayoutAnimated {
  const auto node = [self buildLabelNode];
  const auto view = [[UIView alloc] init];
  const auto context = [[CRContext alloc] init];
  context.layoutAnimator = [[UIViewPropertyAnimator alloc] init];
  [node reconcileInView:view
      constrainedToSize:CGSizeMake(320, CR_CGFLOAT_FLEXIBLE)
            withOptions:CRNodeLayoutOptionsSizeContainerViewToFit];
  [node registerNodeHierarchyInContext:context];
  XCTAssert(view.subviews.count == 1);
  [self assertLabelDidLayout:view.subviews.firstObject];
}

- (void)testNestedLayout {
  const auto node = [CRNode nodeWithType:UIView.self layoutSpec:^(CRNodeLayoutSpec *spec) {
    [spec set:CR_KEYPATH(spec.view, backgroundColor) value:UIColor.redColor];
    [spec set:CR_KEYPATH(spec.view, yoga.padding) value:@42];
  }];
  [node appendChildren:@[
     [self buildLabelNode],
     [self buildLabelNode],
     [self buildLabelNode]
  ]];
  const auto containerView = [[UIView alloc] init];
  const auto context = [[CRContext alloc] init];
  [node registerNodeHierarchyInContext:context];

  [node reconcileInView:containerView
      constrainedToSize:CGSizeMake(320, CR_CGFLOAT_FLEXIBLE)
            withOptions:CRNodeLayoutOptionsSizeContainerViewToFit];

  const auto view = containerView.subviews.firstObject;
  const auto sv = view.subviews;

  XCTAssertNotNil(view);
  [self assertLabelDidLayout:sv[0]];
  [self assertLabelDidLayout:sv[1]];
  [self assertLabelDidLayout:sv[2]];

  XCTAssert(fabs(CGRectGetMaxY(sv[0].frame) - sv[1].frame.origin.y) <= 1.0);
  XCTAssert(fabs(CGRectGetMaxY(sv[1].frame) - sv[2].frame.origin.y) <= 1.0);
}

- (void)testThrowExeptionWhenIllegalControllerTypeIsPassedAsArgument {
  BOOL test = NO;
  CRNode *node = nil;
  @try {
    node = [CRNode nodeWithType:UIView.self
                     layoutSpec:^(CRNodeLayoutSpec *spec) {}];
    [node bindController:TestStatelessController.class
            initialState:CRNullState.null
                   props:CRNullProps.null];
    test = YES;
  }
  @catch(NSException *e) {
    test = NO;
  }
  XCTAssertTrue(test);
  XCTAssertNotNil(node);

  test = NO;
  node = nil;
  @try {
    node = [CRNode nodeWithType:UIView.self
                            key:@"1"
                     layoutSpec:^(CRNodeLayoutSpec *spec) {}];
    [node bindController:TestController.class
            initialState:CRNullState.null
                   props:CRNullProps.null];
    test = YES;
  }
  @catch(NSException *e) {
    test = NO;
  }
  XCTAssertTrue(test);
  XCTAssertNotNil(node);

  test = NO;
  node = nil;
  @try {
    node = [CRNode nodeWithType:UIView.self
                     layoutSpec:^(CRNodeLayoutSpec *spec) {}];
    [node bindController:TestController.class
            initialState:CRNullState.null
                   props:CRNullProps.null];
    test = YES;
  }
  @catch(NSException *e) {
    test = NO;
  }
  XCTAssertFalse(test);

  test = NO;
  node = nil;
  @try {
    node = [CRNode nodeWithType:UIView.self
                            key:@"1"
                     layoutSpec:^(CRNodeLayoutSpec *spec) {}];
    [node bindController:TestStatelessController.class
            initialState:CRNullState.null
                   props:CRNullProps.null];
    test = YES;
  }
  @catch(NSException *e) {
    test = NO;
  }
  XCTAssertFalse(test);

  test = NO;
  node = nil;
  @try {
    node = [CRNode nodeWithType:UIView.self
                            key:@"1"
                     layoutSpec:^(CRNodeLayoutSpec *spec) {}];
    test = YES;
  }
  @catch(NSException *e) {
    test = NO;
  }
  XCTAssertTrue(test);
}

- (void)testThatControllerIsPassedDownToNodeSubtree {
  __block auto expectRootNodeHasController = NO;
  __block auto expectRooNodeHasState = NO;
  __block auto expectRootNodeHasProps = NO;
  __block auto expectLeafNodeHasController = NO;
  __block auto expectLeafNodeHasState = NO;
  __block auto expectLeafNodeHasProps = NO;
  const auto root = [CRNode nodeWithType:UIView.class
                                     key:@"foo"
                              layoutSpec:^(CRNodeLayoutSpec *spec) {

    const auto controller = [spec controllerOfType:TestController.class];
    expectRootNodeHasController = CR_DYNAMIC_CAST(TestController, controller);
    expectRooNodeHasState = CR_DYNAMIC_CAST(CRNullState, controller.state);
    expectRootNodeHasProps = CR_DYNAMIC_CAST(CRNullProps, controller.props);
  }];
  [root bindController:TestController.class initialState:CRNullState.null props:CRNullProps.null];

  const auto leaf = [CRNode nodeWithType:UIView.class
                              layoutSpec:^(CRNodeLayoutSpec *spec) {
    const auto controller = [spec controllerOfType:TestController.class];
    expectLeafNodeHasController = CR_DYNAMIC_CAST(TestController, controller);
    expectLeafNodeHasState = CR_DYNAMIC_CAST(CRNullState, controller.state);
    expectLeafNodeHasProps = CR_DYNAMIC_CAST(CRNullProps, controller.props);
  }];
  [root appendChildren:@[leaf]];

  const auto context = [[CRContext alloc] init];
  [root registerNodeHierarchyInContext:context];

  const auto view = [[UIView alloc] init];
  [root reconcileInView:view
      constrainedToSize:CGSizeMake(320, CR_CGFLOAT_FLEXIBLE)
            withOptions:CRNodeLayoutOptionsSizeContainerViewToFit];
  XCTAssertTrue(expectRootNodeHasController);
  XCTAssertTrue(expectRooNodeHasState);
  XCTAssertTrue(expectRootNodeHasProps);
  XCTAssertTrue(expectLeafNodeHasController);
  XCTAssertTrue(expectLeafNodeHasState);
  XCTAssertTrue(expectLeafNodeHasProps);
}

@end

@implementation TestController
@end

@implementation TestStatelessController
@end
