import XCTest
import CoreRenderObjC
import CoreRender

class FooCoordinator: Coordinator {
  var count: Int = 0
  func increase() { count += 1 }
}

class BarCoordinator: Coordinator {
}

class CRSwiftInteropTests: XCTestCase {

  func testGetCoordinator() {
    let context = Context()

    Component<FooCoordinator>(context: context) { _, _ in
      VStackNode {
        LabelNode(text: "Foor")
        LabelNode(text: "Bar")
        Component<FooCoordinator>(context: context) { _, _ in
          ButtonNode(key: "Hi")
        }
      }
    }
  }

}

