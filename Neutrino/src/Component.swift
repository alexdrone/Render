import UIKit

public protocol UIComponentProtocol: class, UINodeDelegateProtocol {
  /// The component-tree context.
  weak var context: UIContextProtocol? { get }
  /// The view in which the component is going to be rendered.
  weak var canvasView: UIView? { get }
  /// Canvas bounding rect.
  var canvasSize: () -> CGSize { get set }
  /// Set the canvas view for this component.
  /// - parameter view: The view in which the component is going to be rendered.
  /// - parameter useBoundsAsCanvasSize: if 'true' the canvas size will return the view bounds.
  /// - parameter renderOnCanvasSizeChange: if 'true' the components will automatically
  /// trigger 'setNeedsRender' whenever the canvas view changes its bounds.
  func setCanvas(view: UIView, options: [UIComponentCanvasOption])
  /// Mark the component for rendering.
  func setNeedsRender(layoutAnimator: UIViewPropertyAnimator?)
  /// Type-erased state associated to this component.
  /// - note: *Internal only.*
  var anyState: UIStateProtocol { get }
  /// Type-erased props associated to this component.
  /// - note: *Internal only.*
  var anyProps: UIPropsProtocol { get }
}

public enum UIComponentCanvasOption: Int {
  // The canvas size will return the view bounds.
  case useBoundsAsCanvasSize
  /// Triggers 'setNeedsRender' whenever the canvas view changes its bounds.
  case renderOnCanvasSizeChange
  /// If the component can overflow in the horizontal axis.
  case flexibleWidth
  /// If the component can overflow in the vertical axis.
  case flexibleHeight
}

// MARK: - UIComponent

open class UIComponent<S: UIStateProtocol, P: UIPropsProtocol>: UIComponentProtocol {
  /// The root node (built as a result of the 'render' method).
  public var root: UINodeProtocol = UINilNode.nil
  /// The component parent (nil for root components).
  public weak var parent: UIComponentProtocol?
  /// The state associated with this component.
  /// A state is always associated to a unique component key and it's a unique instance living
  /// in the context identity map.
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
  /// Use props to pass data & event handlers down to your child components.
  public var props: P = P()
  public var anyProps: UIPropsProtocol { return props }
  public var anyState: UIStateProtocol { return state }
  /// A unique key for the component (necessary if the component is stateful).
  public let key: String?
  /// Forwards node layout method callbacks.
  public weak var delegate: UINodeDelegateProtocol?
  public weak var context: UIContextProtocol?
  public private(set) weak var canvasView: UIView? {
    didSet {
      assert(parent == nil, "Unable to set a canvas view on a non-root component.")
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
    hookInspectorIfAvailable()
  }

  public func setCanvas(view: UIView, options: [UIComponentCanvasOption] =
    [.useBoundsAsCanvasSize, .renderOnCanvasSizeChange, .flexibleHeight]) {
    canvasView = view
    context?.canvasView = canvasView
    if options.contains(.useBoundsAsCanvasSize) {
      canvasSize = { [weak self] in
        var size = self?.canvasView?.bounds.size ?? CGSize.zero
        size.height = options.contains(.flexibleHeight) ? CGFloat.max : size.height
        size.width = options.contains(.flexibleWidth) ? CGFloat.max : size.width
        return size
      }
    }
    boundsObserver = nil
    if options.contains(.renderOnCanvasSizeChange) {
      boundsObserver = UIContextViewBoundsObserver(view: view) { [weak self] _ in
        self?.setNeedsRender()
      }
    }
  }

  public func setNeedsRender(layoutAnimator: UIViewPropertyAnimator? = nil) {
    assert(Thread.isMainThread)
    guard parent == nil else {
      parent?.setNeedsRender(layoutAnimator: layoutAnimator)
      return
    }
    guard let context = context, let view = canvasView else {
      fatalError("Attempting to render a component without a canvas view and/or a context.")
    }
    // *Optional* the property animator that is going to be used for frame changes in the component
    // subtree. This field is auotmatically reset to 'nil' at the end of every 'render' pass.
    if let layoutAnimator = layoutAnimator {
      context.layoutAnimator = layoutAnimator
    }
    let node = render(context: context)
    node.associatedComponent = self
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
    inspectorMarkDirty()

    // Reset the animatable frame changes to default.
    context.layoutAnimator = nil
  }

  /// Builds the node hierarchy for this component.
  /// The render() function should be pure, meaning that it does not modify component state,
  /// it returns the same result each time it’s invoked.
  /// - note: Subclasses *must* override this method.
  /// - parameter context: The component-tree context.
  open func render(context: UIContextProtocol) -> UINodeProtocol {
    return UINilNode.nil
  }

  open func nodeDidMount(_ node: UINodeProtocol, view: UIView) {
    delegate?.nodeDidMount(node, view: view)
  }

  open func nodeWillLayout(_ node: UINodeProtocol, view: UIView) {
    delegate?.nodeWillLayout(node, view: view)
  }

  open func nodeDidLayout(_ node: UINodeProtocol, view: UIView) {
    delegate?.nodeDidLayout(node, view: view)
  }
}

// MARK: - UIContextViewBoundsObserver

private final class UIContextViewBoundsObserver: NSObject {
  // The observed canvas view.
  private weak var view: UIView?
  // The callback that is going to be invoked whenever the observed view changes its bounds.
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
