import XCTest
import UIKit
@testable import CoreRender

class CRSwiftInteropTests: XCTestCase {

  func buildLabelNode() -> Node<UILabel> {
    let _ = LayoutOptions.none
    return makeNode(type: UILabel.self, layoutSpec: { spec in
      set(spec, keyPath: \.text, value: "Hello")
      set(spec, keyPath: \.yoga.margin, value: 5)
    })
  }
  
}
