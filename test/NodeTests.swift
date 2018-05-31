import XCTest
import UIKit
@testable import RenderNeutrino

class NodeTests: XCTestCase {

  func testSimpleViewRendering() {
    let node = makeNode(size: C.smallSize)
    let container = makeContainerView()
    node.reconcile(in: container, size: container.bounds.size, options: [])
    XCTAssertNotNil(node.renderedView)
    XCTAssert(node.renderedView!.backgroundColor == C.defaultColor)
    XCTAssert(node.renderedView!.frame.width == C.smallSize)
    XCTAssert(node.renderedView!.frame.height == C.smallSize)
  }

  func testSimpleViewReuse() {
    var node = makeNode(size: C.smallSize)
    let container = makeContainerView()
    node.reconcile(in: container, size: container.bounds.size, options: [])
    XCTAssertNotNil(node.renderedView)
    XCTAssert(container.subviews.count == 1)
    let view = node.renderedView!
    node.reconcile(in: container, size: container.bounds.size, options: [])
    XCTAssert(node.renderedView === view)
    XCTAssert(container.subviews.count == 1)
    node = makeNode(size: C.smallSize)
    node.reconcile(in: container, size: container.bounds.size, options: [])
    XCTAssert(node.renderedView === view)
    XCTAssert(container.subviews.count == 1)
  }

  func testComplexViewReuse() {
    func makeChild() -> UINodeProtocol {
      return makeTextNode(size: C.smallSize)
    }
    let container = makeContainerView()
    var parent = makeNode()
    parent.children([makeChild(), makeChild(), makeChild()])
    parent.reconcile(in: container, size: container.bounds.size, options: [])
    func makeSet() -> Set<ObjectIdentifier> {
      var set = Set<ObjectIdentifier>()
      set.insert(ObjectIdentifier(container.subviews.first!))
      for subview in container.subviews.first!.subviews {
        set.insert(ObjectIdentifier(subview))
      }
      return set
    }
    let set = makeSet()
    parent = makeNode()
    parent.children([makeChild(), makeChild(), makeChild()])
    parent.reconcile(in: container, size: container.bounds.size, options: [])
    XCTAssert(set == makeSet())
    parent.children([makeChild(), makeChild(), makeChild(), makeChild()])
    parent.reconcile(in: container, size: container.bounds.size, options: [])
    XCTAssert(makeSet().subtracting(set).count == 1)
  }

  func testParentWrapChildLayout() {
    let parent = makeNode()
    let child = makeNode(size: C.smallSize)
    parent.children([child])
    let container = makeContainerView()
    parent.reconcile(in: container, size: container.bounds.size, options: [])
    XCTAssertNotNil(parent.renderedView)
    XCTAssertNotNil(child.renderedView)
    for node in [parent, child] {
      XCTAssert(node.renderedView!.frame.width == C.smallSize)
      XCTAssert(node.renderedView!.frame.height == C.smallSize)
    }
    parent.reconcile(in: container, size: container.bounds.size, options: [])
    XCTAssertNotNil(parent.renderedView)
    XCTAssertNotNil(child.renderedView)
  }

  func testNodeWithKeyAccessor() {
    let key = "foo"
    let parent = makeNode()
    let child = makeNode(key: key, size: C.smallSize)
    parent.children([child])
    let container = makeContainerView()
    parent.reconcile(in: container, size: container.bounds.size, options: [])
    let node = parent.nodeWithKey(key)
    XCTAssert(node === child)
  }

  func testBindView() {
    let target = BindTarget()
    autoreleasepool {
      var parent = makeNode()
      let child1 = makeNode(size: C.smallSize)
      let child2 = makeNode(size: C.smallSize)
      let child3 = makeNode(size: C.smallSize)
      parent.children([child1, child2, child3])
      child1.bindView(target: target, keyPath: \.view)
      let container = makeContainerView()
      parent.reconcile(in: container, size: container.bounds.size, options: [])
      XCTAssertNotNil(target.view)
      XCTAssert(container.subviews.first!.subviews.first! === target.view)
      parent = makeNode()
      parent.reconcile(in: container, size: container.bounds.size, options: [])
      XCTAssert(container.subviews.first!.subviews.count == 0)
    }
    XCTAssertNil(target.view)
  }

  func testOverrideConfiguration() {
    let node = makeNode(size: C.smallSize)
    let container = makeContainerView()
    node.reconcile(in: container, size: container.bounds.size, options: [])
    XCTAssertNotNil(node.renderedView)
    XCTAssert(node.renderedView!.backgroundColor == C.defaultColor)
    node.overrides = { view in
      view.clipsToBounds = true
    }
    node.reconcile(in: container, size: container.bounds.size, options: [])
    XCTAssert(node.renderedView!.clipsToBounds == true)
  }

  func testDelegateIsInvoked() {
    let node = makeNode(size: C.smallSize)
    let container = makeContainerView()
    let delegate = BindTarget()
    node.delegate = delegate
    node.reconcile(in: container, size: container.bounds.size, options: [])
    XCTAssertTrue(delegate.didLayoutCalled)
    XCTAssertTrue(delegate.willLayoutCalled)
    XCTAssertTrue(delegate.didMountCalled)
  }

  func testDelegateIsNotInvoked() {
    let node = makeNode(size: C.smallSize)
    let container = makeContainerView()
    let delegate = BindTarget()
    node.delegate = delegate
    node.reconcile(in: container, size: container.bounds.size, options: [.preventDelegateCallbacks])
    XCTAssertFalse(delegate.didLayoutCalled)
    XCTAssertFalse(delegate.willLayoutCalled)
  }
}

struct C {
  static let smallSize: CGFloat = 64
  static let defaultColor: UIColor = .red
}

func makeContainerView() -> UIView {
  return UIView(frame: CGRect(origin: .zero, size: CGSize(width: 640, height: 640)))
}

func makeNode(key: String? = nil, size: CGFloat? = nil) -> UINode<UIView> {
  return UINode<UIView>(key: key) { config in
    config.set(\UIView.backgroundColor, C.defaultColor)
    guard let size = size else { return }
    config.set(\.yoga.width, size)
    config.set(\.yoga.height, size)
  }
}

func makeTextNode(key: String? = nil, size: CGFloat? = nil) -> UINode<UILabel> {
  return UINode<UILabel>(key: key) { config in
    config.set(\UILabel.backgroundColor, C.defaultColor)
    config.set(\UILabel.text, "foo")
    guard let size = size else { return }
    config.set(\UILabel.yoga.width, size)
    config.set(\UILabel.yoga.height, size)
  }
}

class BindTarget: UINodeDelegateProtocol {
  weak var view: UIView? = nil
  var (didMountCalled, willLayoutCalled, didLayoutCalled) = (false, false, false)

  func nodeDidMount(_ node: UINodeProtocol, view: UIView) {
    didMountCalled = true
  }

  func nodeWillLayout(_ node: UINodeProtocol, view: UIView) {
    willLayoutCalled = true
  }

  func nodeDidLayout(_ node: UINodeProtocol, view: UIView) {
    didLayoutCalled = true
  }
}
