@import CoreRenderObjC;
@import XCTest;

@interface CRNodeTests : XCTestCase
@property(nonatomic, weak) UILabel *testOutlet;
@end

@interface TestCoordinator : CRCoordinator
@end

@interface TestStatelessCoordinator : CRCoordinator
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
  const auto node = [CRNode nodeWithType:UIView.self
                              layoutSpec:^(CRNodeLayoutSpec *spec) {
                                [spec set:CR_KEYPATH(spec.view, backgroundColor)
                                    value:UIColor.redColor];
                                [spec set:CR_KEYPATH(spec.view, yoga.padding) value:@42];
                              }];
  [node appendChildren:@[ [self buildLabelNode], [self buildLabelNode], [self buildLabelNode] ]];
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

- (void)testThatCoordinatorIsPassedDownToNodeSubtree {
  __block auto expectRootNodeHasCoordinator = NO;
  __block auto expectLeafNodeHasCoordinator = NO;
  const auto root =
      [CRNode nodeWithType:UIView.class
           reuseIdentifier:nil
                       key:@"foo"
                  viewInit:nil
                layoutSpec:^(CRNodeLayoutSpec *spec) {
                  const auto coordinator = [spec coordinatorOfType:TestCoordinator.class];
                  expectRootNodeHasCoordinator = CR_DYNAMIC_CAST(TestCoordinator, coordinator);
                }];
  [root bindCoordinator:self.testDescriptor];

  const auto leaf =
      [CRNode nodeWithType:UIView.class
                layoutSpec:^(CRNodeLayoutSpec *spec) {
                  const auto coordinator = [spec coordinatorOfType:TestCoordinator.class];
                  expectLeafNodeHasCoordinator = CR_DYNAMIC_CAST(TestCoordinator, coordinator);
                }];
  [root appendChildren:@[ leaf ]];

  const auto context = [[CRContext alloc] init];
  [root registerNodeHierarchyInContext:context];

  const auto view = [[UIView alloc] init];
  [root reconcileInView:view
      constrainedToSize:CGSizeMake(320, CR_CGFLOAT_FLEXIBLE)
            withOptions:CRNodeLayoutOptionsSizeContainerViewToFit];
  XCTAssertTrue(expectRootNodeHasCoordinator);
  XCTAssertTrue(expectLeafNodeHasCoordinator);
}

- (CRCoordinatorDescriptor *)testDescriptor {
  return [[CRCoordinatorDescriptor alloc] initWithType:TestCoordinator.class key:@"test"];
}

@end

@implementation TestCoordinator
@end

@implementation TestStatelessCoordinator
@end
