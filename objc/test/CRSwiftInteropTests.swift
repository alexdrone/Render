import XCTest
import UIKit
@testable import CoreRender

class FooController: StatelessController<Props> { }

class CRSwiftInteropTests: XCTestCase {

  func buildLabelNode() -> ConcreteNode<UILabel> {
    let _ = LayoutOptions.none
    return Node(type: UILabel.self, layoutSpec: { spec in
      set(spec, keyPath: \.text, value: "Hello")
      set(spec, keyPath: \.yoga.margin, value: 5)
    })
  }

  func testNodeWithAController() {
    let node = Node(type: UIView.self, controller: FooController.self) { spec in }
    XCTAssertNotNil(node)
  }
}
