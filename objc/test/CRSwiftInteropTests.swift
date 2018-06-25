import XCTest
import UIKit
@testable import CoreRenderObjC

class CRSwiftInteropTests: XCTestCase {

  func buildLabelNode() -> Node<UILabel> {
    let _ = LayoutOptions.none
    return makeNode(type: UILabel.self, layoutSpec: { spec in
      set(spec: spec, keyPath: \.text, value: "Hello")
      set(spec: spec, keyPath: \.yoga.margin, value: 5)
    })
  }
  
}
