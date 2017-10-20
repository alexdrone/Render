import UIKit

public protocol UIComponentProtocol: class, UINodeDelegateProtocol {
  /// The component-tree context.
  weak var context: UIContextProtocol? { get }
  /// The target container view.
  weak var canvasView: UIView? { get }
  /// The canvas boundaries for the component.
  var canvasSize: () -> CGSize { get set }
  /// Set the view this component is going to be rendered in.
  func setCanvas(view: UIView,
                 useBoundsAsCanvasSize: Bool,
                 automaticallyRenderOnCanvasSizeChange: Bool)
  /// Mark the component for rendering.
  func setNeedsRender()
}

// MARK: - UIComponent

open class UIComponent<S: UIStateProtocol, P: UIPropsProtocol>: UIComponentProtocol {
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
  public private(set) weak var canvasView: UIView? {
    didSet {
      assert(parent == nil, "Unable to set a target view on a non-root component.")
    }
  }
  public var canvasSize: () -> CGSize = {
    return CGSize(width: UIScreen.main.bounds.width, height: CGFloat.max)
  }
  private var boundsObserver: UIContextViewBoundsObserver? = nil

  required public init(context: UIContextProtocol, key: String? = nil) {
    assert(context._componentInitFromContext, "Explicit init call is prohibited.")
    self.key = key
    self.context = context
  }

  public func setCanvas(view: UIView,
                        useBoundsAsCanvasSize: Bool = true,
                        automaticallyRenderOnCanvasSizeChange: Bool = true) {
    canvasView = view
    if useBoundsAsCanvasSize {
      canvasSize = { [weak self] in return self?.canvasView?.bounds.size ?? CGSize.zero }
    }
    boundsObserver = nil
    if automaticallyRenderOnCanvasSizeChange {
      boundsObserver = UIContextViewBoundsObserver(view: view) { [weak self] _ in
        self?.setNeedsRender()
      }
    }
  }

  public func setNeedsRender() {
    assert(Thread.isMainThread)
    guard parent == nil else {
      parent?.setNeedsRender()
      return
    }
    guard let context = context, let view = canvasView else {
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
    retrieveAllKeys(node: node)

    context.pool.flushObsoleteStates(validKeys: keys)
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

// MARK: - UIProps

/// Represents the component props.
public protocol UIPropsProtocol: Codable {
  init()
}

public class UINilProps: UIPropsProtocol {
  static let `nil` = UINilProps()
  public required init() { }
}

// MARK: - UIContextViewBoundsObserver

private final class UIContextViewBoundsObserver: NSObject {
  // The observed view.
  private weak var view: UIView?
  // The desired callback.
  private let callback: (CGSize) -> Void
  // KVO observation token.
  private var token: NSKeyValueObservation?
  // The last recorded size.
  private var size = CGSize.zero

  init(view: UIView, callback: @escaping (CGSize) -> Void) {
    self.view = view
    self.callback = callback
    super.init()
    self.token = view.observe(\UIView.bounds,
                              options: [.initial, .new, .old]) { [weak self] (view, change) in
      let oldSize = self?.size ?? CGSize.zero
      if view.bounds.size != oldSize {
        self?.size = view.bounds.size
        self?.callback(view.bounds.size)
      }
    }
  }
}
