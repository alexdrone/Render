import UIKit

public protocol UIComponentProtocol: UINodeDelegateProtocol, Disposable {
  /// The component-tree context.
  var context: UIContextProtocol? { get }
  /// A unique key for the component (necessary if the component is stateful).
  var key: String? { get }
  /// The root node (built as a result of the 'render' method).
  var root: UINodeProtocol { get }
  /// *Optional* node delegate.
  var delegate: UINodeDelegateProtocol? { get set }
  /// The component parent (nil for root components).
  var parent: UIComponentProtocol? { get }
  /// *IThe view in which the component is going to be rendered.
  var canvasView: UIView? { get }
  /// Wheter a component’s output is not affected by the current change in state or props.
  /// The default behavior is to re-render on every state change, and in the vast majority of cases
  /// you should rely on the default behavior.
  /// Returning false does not prevent child components from re-rendering when their state changes.
  var shouldUpdate: Bool { get }
  /// Set the canvas view for this component.
  /// - parameter view: The view in which the component is going to be rendered.
  /// - parameter useBoundsAsCanvasSize: if 'true' the canvas size will return the view bounds.
  /// - parameter renderOnCanvasSizeChange: if 'true' the components will automatically
  /// trigger 'setNeedsRender' whenever the canvas view changes its bounds.
  func setCanvas(view: UIView, options: [UIComponentCanvasOption])
  /// Mark the component for rendering.
  func setNeedsRender(options: [UIComponentRenderOption])
  /// Trigger a render pass if the component was set dirty after 'suspendComponentRendering'
  /// has been invoked on the context.
  /// - note: In most scenarios you don't have to manually call this method - the context will
  /// automatically resume rendering on invalidated components when the suspension is terminated.
  func resumeFromSuspendedRenderingIfNecessary()
  /// Type-erased state associated to this component.
  /// - note: *Internal only.*
  var anyState: UIStateProtocol { get }
  /// Type-erased props associated to this component.
  /// - note: *Internal only.*
  var anyProp: UIPropsProtocol { get }
  /// Builds the component node.
  /// - note: Use this function to insert the node as a child of a pre-existent node hierarchy.
  func asNode() -> UINodeProtocol
}

public enum UIComponentCanvasOption: Int {
  // The canvas size will return the view bounds.
  case useBoundsAsCanvasSize
  /// If the component can overflow in the horizontal axis.
  case flexibleWidth
  /// If the component can overflow in the vertical axis.
  case flexibleHeight
  /// Default canvas option.
  public static func defaults() -> [UIComponentCanvasOption] {
    return [
      .useBoundsAsCanvasSize,
      .flexibleHeight]
  }
}

public enum UIComponentRenderOption {
  /// Provide an animator that will transition the frame change caused by the new computed layout.
  case animateLayoutChanges(animator: UIViewPropertyAnimator)
  /// Useful whenever a component in an inner context (e.g. a component embedded in a cell)
  /// wants to trigger a re-render from the top down on the parent context.
  /// This also trigger a 'reloadData' if the component is embedded in a
  /// *UIComponentTableViewController*'s cell.
  /// - note: Nested context are pretty rare and adopted for performance optimisation reasons only.
  /// Creating your own nested contexts is discouraged.
  case propagateToParentContext
  /// Prevent *beginUpdates()* and *endUpdates()* to be called on the table view on this instance
  /// of render.
  case preventTableUpdates
}

// MARK: - UIComponent

/// Component baseclass.
open class UIComponent<S: UIStateProtocol, P: UIPropsProtocol>: NSObject, UIComponentProtocol {
  /// The root node (built as a result of the 'render' method).
  public var root: UINodeProtocol = UINilNode.nil {
    didSet {
      root.associatedComponent = self
      root.updateMode = shouldUpdate ? .update : .ignore
      setKey(node: root)
    }
  }
  /// The component pa rent (nil for root components).
  public weak var parent: UIComponentProtocol?
  /// The state associated with this component.
  /// A state is always associated to a unique component key and it's a unique instance living
  /// in the context identity map.
  open var state: S {
    get {
      let newInstance = S()
      if newInstance is UINilState {
        return UINilState.nil as! S
      }
      guard let key = key, !(newInstance is UINilState) else {
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
    }
  }
  /// Use props to pass data & event handlers down to your child components.
  open var props: P = P()
  public var anyProp: UIPropsProtocol { return props }
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
  /// The bounding rect for the the layout computation.
  /// It can exceed the size of the canvas.
  public var renderSize: () -> CGSize = {
    return CGSize(width:
      UIScreen.main.bounds.size.width, height: CGFloat.max)
  }
  open var shouldUpdate: Bool { return true }

  private var setNeedsRenderCalledDuringSuspension: Bool = false

  /// Never construct your component directly but do it through the *UIContext* factory methods.
  required public init(context: UIContextProtocol, key: String? = nil) {
    assert(context._componentInitFromContext, "Explicit init call is prohibited.")
    self.key = key
    self.context = context
    super.init()
    hookInspectorIfAvailable()
    hookHotReload()
    logAlloc(type: String(describing: type(of: self)), object: self)
  }

  deinit {
    logDealloc(type: String(describing: type(of: self)), object: self)
  }

  /// Whether this object has been disposed or not.
  /// Once an object is disposed it cannot be used any longer.
  public var isDisposed: Bool = false

  public func setCanvas(
    view: UIView,
    options: [UIComponentCanvasOption] = UIComponentCanvasOption.defaults()
  ) -> Void {
    assert(Thread.isMainThread)
    guard !isDisposed else {
      disposedWarning()
      return
    }
    canvasView = view
    context?._canvasView = canvasView
    if options.contains(.useBoundsAsCanvasSize) {
      renderSize = { [weak self] in
        var size = CGSize.zero
        if let context = self?.context as? UIContext {
          size = context.canvasSize
        } else if let canvasViewBounds = self?.canvasView?.bounds.size {
          size = canvasViewBounds
        }
        size.height = options.contains(.flexibleHeight) ? CGFloat.max : size.height
        size.width = options.contains(.flexibleWidth) ? CGFloat.max : size.width
        return size
      }
    }
  }

  /// Called when ⌘ + R is pressed to reload the component.
  func forceComponentReload() {
    assert(Thread.isMainThread)
    guard !isDisposed else {
      disposedWarning()
      return
    }
    guard parent == nil, canvasView != nil else { return }
    self.setNeedsRender()
    //#if RENDER_MOD_STYLESHEET
    try? UIStylesheetManager.default.load(file: nil)
    //#endif
  }

  public func setNeedsRender(options: [UIComponentRenderOption] = []) {
    assert(Thread.isMainThread)
    guard !isDisposed else {
      disposedWarning()
      return
    }
    guard parent == nil else {
      parent?.setNeedsRender(options: options)
      return
    }
    guard let context = context, let view = canvasView else {
      self.root = UINilNode.nil
      return
    }
    // Updates the context's screen state.
    context._screenStateFactory.bounds = renderSize()
    //#if RENDER_MOD_STYLESHEET
    UIStylesheetManager.default.canvasSize = renderSize()
    //#endif
    // Rendering is suspended for this context for the time being.
    // 'resumeFromSuspendedRenderingIfNecessary' will automatically be called when the render
    // context will be resumed.
    if context._isRenderSuspended {
      setNeedsRenderCalledDuringSuspension = true
      return
    }
    var layoutAnimator: UIViewPropertyAnimator? = nil
    var propagateToParentContext: Bool = false
    for option in options {
      switch option {
      case .animateLayoutChanges(let animator):
        layoutAnimator = animator
      case .propagateToParentContext:
        propagateToParentContext = true
      case .preventTableUpdates:
        context._preventTableUpdates = true
      }
    }
    // *Optional* the property animator that is going to be used for frame changes in the component
    // subtree. This field is auotmatically reset to 'nil' at the end of every 'render' pass.
    if let layoutAnimator = layoutAnimator {
      context.layoutAnimator = layoutAnimator
    }
    root = render(context: context)
    root.reconcile(in: view, size: renderSize(), options: [])

    context.didRenderRootComponent(self)
    //context.flushObsoleteState(validKeys: root._retrieveKeysRecursively())
    inspectorMarkDirty()

    // Reset the animatable frame changes to default.
    context.layoutAnimator = nil
    if propagateToParentContext, let tableViewController = context._associatedTableViewController {
      tableViewController.reloadData()
    }
    if propagateToParentContext, let parentContext = context._parentContext {
      parentContext.pool.allComponent().filter { $0.parent == nil }.forEach {
        $0.setNeedsRender(options: [.propagateToParentContext])
      }
    }
  }

  public func resumeFromSuspendedRenderingIfNecessary() {
    assert(Thread.isMainThread)
    guard !isDisposed else {
      disposedWarning()
      return
    }
    guard setNeedsRenderCalledDuringSuspension else {
      return
    }
    setNeedsRenderCalledDuringSuspension = false
    setNeedsRender()
  }

  private func setKey(node: UINodeProtocol) {
    assert(Thread.isMainThread)
    guard !isDisposed else {
      disposedWarning()
      return
    }
    if let key = key, node.key == nil {
      node.key = key
    }
    #if DEBUG
    node._debugPropDescription =
      props.reflectionDescription()
    node._debugStateDescription =
      state.reflectionDescription()
    #endif
  }

  public func childKey<T>(_ type: T.Type, _ index: Int = -1) -> String {
    let indexstr = index >= 0 ? "-\(index)" : ""
    return childKey(string(fromType: type) + indexstr)
  }

  /// Returns the desired child key prefixed with the key of the father.
  public func childKey(_ postfix: String) -> String {
    var parentKey: String = ""
    func findParentKeyRecursively(component: UIComponentProtocol) {
      if let key = component.key {
        parentKey = key
      } else if let parent = component.parent {
        findParentKeyRecursively(component: parent)
      }
    }
    findParentKeyRecursively(component: self)
    return "\(parentKey)-\(postfix)"
  }

  /// Builds the component node.
  /// - note: Use this function to insert the node as a child of a pre-existent node hierarchy.
  public func asNode() -> UINodeProtocol {
    guard let context = context else {
      fatalError("Attempting to render a component without a valid context.")
    }
    if root !== UINilNode.nil {
      return root
    }
    let node = render(context: context)
    self.root = node
    return node
  }

  /// Retrieves the component from the context for the key passed as argument.
  /// If no component is registered yet, a new one will be allocated and returned.
  /// - parameter type: The desired *UIComponent* subclass.
  /// - parameter key: The unique key ('nil' for a transient component).
  /// - parameter props: Configurations and callbacks passed down to the component.
  public func childComponent<S, P, C: UIComponent<S, P>>(
    _ type: C.Type,
    key: String? = nil,
    props: P = P()
  ) -> C {
    guard let context = context else {
      fatalError("Attempting to create a component without a valid context.")
    }
    if let key = key {
      return context.component(type, key: key, props: props, parent: self)
    } else {
      return context.transientComponent(type, props: props, parent: self)
    }
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

  /// Dispose the object and makes it unusable.
  open func dispose() {
    isDisposed = true
    // Resets props and state.
    props = P()
    renderSize = { CGSize.zero }
    // Flushes all of the targets.
    context = nil
    delegate = nil
    parent = nil
    canvasView = nil
    // Disposes the root node.
    root.dispose()
    NotificationCenter.default.removeObserver(self)
  }
}

// MARK: - UIComponentSubclasses

/// A component without *props* nor *state*.
public typealias UIPureComponent = UIComponent<UINilState, UINilProps>

/// A component without any *state* but with *props* configured from the outside.
open class UIStatelessComponent<P: UIPropsProtocol>: UIComponent<UINilState, P> { }

/// A component without a *state* but without any *props* configured from the outside.
open class UIProplessComponent<S: UIStateProtocol>: UIComponent<S, UINilProps> { }
