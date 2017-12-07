import XCTest
import UIKit
@testable import RenderNeutrino

class ContextTests: XCTestCase {

  class Sa: UIState { }
  class Sb: UIState { }
  class Ca: UIComponent<Sa, UINilProps> {
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      return UINode<UIView>() { _ in }
    }
  }
  class Cb: UIComponent<Sb, UINilProps> { }
  class Cc: UIComponent<UINilState, UINilProps> { }

  func testUniquenessOfStateObjects() {
    let context = UIContext()
    let sa1 = context.state(Sa.self, key: "foo")
    let sa2 = context.state(Sa.self, key: "foo")
    XCTAssertTrue(sa1 === sa2)
    let sb1 = context.state(Sb.self, key: "bar")
    let sb2 = context.state(Sb.self, key: "bar")
    XCTAssertTrue(sb1 === sb2)
  }

  func testFlushObsoleteState() {
    let context = UIContext()
    let sa1 = context.state(Sa.self, key: "foo")
    context.flushObsoleteState(validKeys: Set<String>())
    let sa2 = context.state(Sa.self, key: "foo")
    XCTAssertFalse(sa1 === sa2)
  }

  func testUniquenessOfStatefulComponent() {
    let context = UIContext()
    let ca1 = context.component(Ca.self, key: "foo")
    let ca2 = context.component(Ca.self, key: "foo")
    XCTAssertTrue(ca1 === ca2)
    let cb1 = context.component(Cb.self, key: "bar")
    let ca3 = context.component(Ca.self, key: "foo", props: UINilProps.nil, parent: cb1)
    XCTAssertTrue(ca1 === ca3)
    XCTAssertTrue(ca1.parent === cb1)
  }

  func testTransientComponent() {
    let context = UIContext()
    let cc1 = context.transientComponent(Cc.self)
    let cc2 = context.transientComponent(Cc.self)
    XCTAssertFalse(cc1 === cc2)
  }

  func testContextDelegate() {
    let context = UIContext()
    let ca1 = context.component(Ca.self, key: "foo")
    let container = makeContainerView()
    ca1.setCanvas(view: container)
    let delegate1 = Delegate()
    context.registerDelegate(delegate1)
    let delegate2 = Delegate()
    context.registerDelegate(delegate2)
    ca1.setNeedsRender()
    XCTAssert(delegate1.lastInvokedTarget === ca1)
    XCTAssert(delegate2.lastInvokedTarget === ca1)
  }

  class Delegate: UIContextDelegate {
    var lastInvokedTarget: UIComponentProtocol? = nil
    func setNeedRenderInvoked(on context: UIContextProtocol, component: UIComponentProtocol) {
      lastInvokedTarget = component
    }
  }
}
