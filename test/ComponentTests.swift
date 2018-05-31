import XCTest
import UIKit
@testable import RenderNeutrino

class ComponentTests: XCTestCase {

  class Ca: UIPureComponent {
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      return makeNode()
    }
  }
  class Sb: UIState { }
  class Cb: UIComponent<Sb, UINilProps> {
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      return makeNode()
    }
  }

  class Cc: UIPureComponent {
    weak var childRef: UIComponentProtocol?

    override func render(context: UIContextProtocol) -> UINodeProtocol {
      childRef = context.component(Cb.self, key: "bar", props: UINilProps.nil, parent: self)
      return childRef!.asNode()
    }
  }

  func testRenderSimpleComponent() {
    let context = UIContext()
    let component = context.transientComponent(Ca.self)
    let container = makeContainerView()
    component.setCanvas(view: container)
    component.setNeedsRender()
    XCTAssertNotNil(container.subviews.first)
    let view = container.subviews.first!
    XCTAssert(view.backgroundColor == C.defaultColor)
  }

  func testRenderSimpleComponentAnimated() {
    let context = UIContext()
    let component = context.transientComponent(Ca.self)
    let container = makeContainerView()
    component.setCanvas(view: container)
    let animator = UIViewPropertyAnimator(duration: 0, dampingRatio: 0, animations: nil)
    component.setNeedsRender(options: [.animateLayoutChanges(animator: animator)])
    XCTAssertNotNil(container.subviews.first)
    let view = container.subviews.first!
    XCTAssert(view.backgroundColor == C.defaultColor)
  }

  func testStatefulComponentKeyGetPropagated() {
    let context = UIContext()
    let component = context.component(Cb.self, key: "foo")
    let container = makeContainerView()
    component.setCanvas(view: container)
    component.setNeedsRender()
    XCTAssert(component.root.key == "foo")
  }

  func testDelegateIsInvoked() {
    let context = UIContext()
    let component = context.transientComponent(Ca.self)
    let container = makeContainerView()
    let delegate = BindTarget()
    component.delegate = delegate
    component.setCanvas(view: container)
    component.setNeedsRender()
    XCTAssertTrue(delegate.didLayoutCalled)
    XCTAssertTrue(delegate.willLayoutCalled)
    XCTAssertTrue(delegate.didMountCalled)
  }

  func testSetNeedsRenderCalledOnChild() {
    let context = UIContext()
    let component = context.transientComponent(Cc.self)
    let container = makeContainerView()
    component.setCanvas(view: container)
    component.setNeedsRender()
    container.subviews.first!.removeFromSuperview()
    component.childRef!.setNeedsRender(options: [])
    XCTAssertNotNil(container.subviews.first)
    let view = container.subviews.first!
    XCTAssert(view.backgroundColor == C.defaultColor)
  }

}
