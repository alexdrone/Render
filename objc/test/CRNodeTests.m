#import <XCTest/XCTest.h>
#import <CoreRender/CoreRender.h>

@interface CRNodeTests : XCTestCase
@property (nonatomic, weak) UILabel *testOutlet;
@end

@interface TestController : CRController
@end

@implementation TestController
@end

@interface TestStatelessController : CRStatelessController
@end

@implementation TestStatelessController
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
  [node registerInContext:context];
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
  [node registerInContext:context];

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
                     controller:TestStatelessController.self
                     layoutSpec:^(CRNodeLayoutSpec *spec) {}];
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
                     controller:TestController.self
                            key:@"1"
                     layoutSpec:^(CRNodeLayoutSpec *spec) {}];
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
                     controller:TestController.self
                     layoutSpec:^(CRNodeLayoutSpec *spec) {}];
    test = YES;
  }
  @catch(NSException *e) {
    test = NO;
  }
  XCTAssertFalse(test);
  XCTAssertNil(node);

  test = NO;
  node = nil;
  @try {
    node = [CRNode nodeWithType:UIView.self
                     controller:TestStatelessController.self
                            key:@"1"
                     layoutSpec:^(CRNodeLayoutSpec *spec) {}];
    test = YES;
  }
  @catch(NSException *e) {
    test = NO;
  }
  XCTAssertFalse(test);
  XCTAssertNil(node);

  test = NO;
  node = nil;
  @try {
    node = [CRNode nodeWithType:UIView.self
                     controller:NSObject.self
                            key:@"1"
                     layoutSpec:^(CRNodeLayoutSpec *spec) {}];
    test = YES;
  }
  @catch(NSException *e) {
    test = NO;
  }
  XCTAssertFalse(test);
  XCTAssertNil(node);
}

@end
