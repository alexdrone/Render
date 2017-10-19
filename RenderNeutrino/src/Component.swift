import UIKit

public protocol UIComponentProtocol: class, UINodeDelegateProtocol {
  /// The component-tree context.
  weak var context: UIContextProtocol? { get }
  /// The target container view.
  weak var containerView: UIView? { get set }
  /// The canvas boundaries for the component.
  var canvasSize: () -> CGSize { get set }
  /// Mark the component for rendering.
  func setNeedsRender()
}

open class UIComponent<S: UIStateProtocol, P: UIPropsProtocol>: UIComponentProtocol {

  public typealias PropsType = P
  public typealias StateType = S

  /// The root node.
  public var root: UINodeProtocol = UINilNode.nil
  /// The component parent (if applicable).
  public weak var parent: UIComponentProtocol?
  /// The state associated to this component.
  public var state: S {
    get {
      guard let key = key, !(S() is UINilState) else {
        fatalError("Key not defined for a non-nil state.")
      }
      guard let context = context else {
        fatalError("No context registered for this component.")
      }
      let currentState: S = context.pool.state(key: key)
      return currentState
    }
    set {
      guard let key = key else {
        fatalError("Attempting to access the state of a key-less component.")
      }
      context?.pool.store(key: key, state: state)
      setNeedsRender()
    }
  }
  /// The props currently associated to this component.
  public var props: P = P()
  /// A unique key for the component (necessary if the component is stateful).
  public let key: String?
  /// Forwards delegates method calls.
  public weak var delegate: UINodeDelegateProtocol?

  public weak var context: UIContextProtocol?
  public weak var containerView: UIView? {
    didSet {
      assert(parent == nil, "Unable to set a target view on a non-root component.")
    }
  }
  public var canvasSize: () -> CGSize = {
    return CGSize(width: UIScreen.main.bounds.width, height: CGFloat.max)
  }

  required public init(context: UIContextProtocol, key: String? = nil) {
    assert(context._componentInitFromContext, "Explicit init call is prohibited.")
    self.key = key
    self.context = context
  }

  public func setNeedsRender() {
    assert(Thread.isMainThread)
    guard parent == nil else {
      parent?.setNeedsRender()
      return
    }
    guard let context = context, let view = containerView else {
      fatalError("Attempting to render a component without a target view and/or a context.")
    }
    let node = render(context: context, state: state, props: props)
    if let key = key {
      if let nodeKey = node.key, nodeKey != key {
        print("warning: The root node has a key \(nodeKey) that differs from the component \(key).")
      }
      node.key = key
    }
    node.reconcile(in: view, size: canvasSize(), options: [])

    var keys = Set<String>()
    func retrieveAllKeys(node: UINodeProtocol) {
      if let key = node.key { keys.insert(key) }
      node.children.forEach { node in retrieveAllKeys(node: node) }
    }
  }

  /// Builds the node hierarchy for this component.
  /// Subclasses to override this method.
  open func render(context: UIContextProtocol, state: S, props: P) -> UINodeProtocol {
    return UINilNode.nil
  }

  /// The view got rendered and added to the view hierarchy.
  open func nodeDidMount(_ node: UINodeProtocol, view: UIView) {
    delegate?.nodeDidMount(node, view: view)
  }
  /// The view is about to be layed out.
  open func nodeWillLayout(_ node: UINodeProtocol, view: UIView) {
    delegate?.nodeWillLayout(node, view: view)
  }
  /// The view just got layed out.
  open func nodeDidLayout(_ node: UINodeProtocol, view: UIView) {
    delegate?.nodeDidLayout(node, view: view)
  }
}

// MARK: - Props

/// Represents the component props.
public protocol UIPropsProtocol: Codable {
  init()
}

public class UINilProps: UIPropsProtocol {
  static let `nil` = UINilProps()
  public required init() { }
}
