import XCTest
import UIKit
@testable import CoreRender

class FooController: StatelessController<FooProps> { }

class FooProps: Props {
  // Must return the type of the controller associated to it.
  @objc override var controllerType: AnyClass { return FooController.self }
}

class CRSwiftInteropTests: XCTestCase {

  func buildLabelNode() -> ConcreteNode<UILabel> {
    let _ = LayoutOptions.none
    return Node(type: UILabel.self, layoutSpec: { spec in
      set(spec, keyPath: \.text, value: "Hello")
      set(spec, keyPath: \.yoga.margin, value: 5)
    })
  }

  func testNodeWithAController() {
    let node = Node(type: UIView.self, props: FooProps()) { spec in }
    XCTAssertNotNil(node)
  }
}
