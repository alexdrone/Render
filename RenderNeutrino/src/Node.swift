import UIKit

// MARK: - Delegate

public protocol UINodeDelegateProtocol: class {
  /// The view got rendered and added to the view hierarchy.
  func nodeDidMount(_ node: UINodeProtocol, view: UIView)
  /// The view is about to be layed out.
  func nodeWillLayout(_ node: UINodeProtocol, view: UIView)
  /// The view just got layed out.
  func nodeDidLayout(_ node: UINodeProtocol, view: UIView)
}

// MARK: - Protocol

public protocol UINodeProtocol: class, UINodeDelegateProtocol {
  /// Whether this is a stateless node or not.
  var isStateless: Bool { get }
  /// The underlying rendered view.
  var renderedView: UIView? { get }
  /// The optional delegate for this node.
  weak var delegate: UINodeDelegateProtocol? { get set }
  /// The parent node (if applicable).
  weak var parent: UINodeProtocol? { get set }
  /// This must be defined if the node is a stateful node.
  /// It uniquely defines a node.
  var key: String? { get }
  /// The reuse identifier for this node is its hierarchy.
  /// Identifiers help Render understand which items have changed.
  var reuseIdentifier: String { get }
  /// The subnodes of this node.
  var children: [UINodeProtocol] { get }
  /// Sets the subnodes of this node.
  @discardableResult func set(children: [UINodeProtocol]) -> UINodeProtocol
  /// This component is the n-th children.
  var index: Int { get set }
  /// Subclasses should override this method.
  /// Construct your subtree here.
  func render()
  /// Re-applies the configuration for the node and compute its layout.
  func layout(in bounds: CGSize, options: [UINodeOption])
  /// Mount the component in the view hierarchy by running its reconciliation algorithm.
  /// This means that only the required changes to the view hierarchy are going to be applied.
  func reconcile(in view: UIView?, size: CGSize?, options: [UINodeOption])

  // Internal.

  /// Internal only - The node properties.
  var _props: UINodePropsProtocol { get }
  /// Internal only - Type erased state.
  var _state: UIStateProtocol { get }
  /// Asks the node to build the backing view for this node.
  func _build(with reusableView: UIView?)
  /// Configure the backing view of this node.
  func _configure(in bounds: CGSize, options: [UINodeOption])
  /// Returns the first mutator in the view hierarchy (if applicable).
  func _findMutatorRecursive<M: UINodeDelegateProtocol>() -> M?
}

// MARK: - Implementation

open class UINode<V: UIView, S: UIStateProtocol, P: UINodePropsProtocol>: UINodeProtocol {

  // The node base class is stateless.
  public fileprivate(set) var _state: UIStateProtocol = S()
  public fileprivate(set) var _props: UINodePropsProtocol = P()

  /// The current node props.
  public var props: P {
    get {
      return _props as! P
    }
    set {
      _props = newValue
      render()
    }
  }

  public let isStateless: Bool = true

  public fileprivate(set) var renderedView: UIView? = nil
  public var delegate: UINodeDelegateProtocol?
  public weak var parent: UINodeProtocol?

  // Since there's no state, there's no key for this component.
  public fileprivate(set) var key: String? = nil
  public fileprivate(set) var reuseIdentifier: String

  public fileprivate(set) var children: [UINodeProtocol] = []
  public var index: Int = 0

  // The creation closure for the view.
  private let create: () -> V
  private var shouldInvokeDidMount: Bool = false
  private weak var bindTarget: AnyObject?

  // The properties for this node.
  var viewProperties: [Int: UIViewProperty] = [:]

  public init(reuseIdentifier: String = String(describing: V.self),
              create: @escaping () -> V = { V() },
              props: P = P()) {
    self.reuseIdentifier = reuseIdentifier
    self._props = props
    self.create = create
    render()
  }

  /// Subclasses should override this method.
  /// Construct your subtree here.
  open func render() {
    reconcile()
  }

  /// Tears down the existing node hierarchy and its configuration.
  open func resetNode() {
    children = []
    viewProperties = [:]
  }

  /// Sets the subnodes of this node.
  @discardableResult public func set(children: [UINodeProtocol]) -> UINodeProtocol {
    self.children = []
    var index = 0
    for child in children {
      child.index = index
      child.parent = self
      self.children.append(child)
      index += 1
    }
    return self
  }

  /// Configure the backing view of this node.
  public func _configure(in bounds: CGSize, options: [UINodeOption]) {
    assert(Thread.isMainThread)
    _build()
    willLayout(options: options)
    // Configure the children recursively.
    for child in children {
      child._configure(in: bounds, options: options)
    }

    // Get hold of the rendered view.
    let view = requireRenderedView()

    let config = view.configuration
    let oldConfigurationKeys = Set(config.appliedConfiguration.keys)
    let newConfigurationKeys = Set(viewProperties.keys)

    let configurationToRestore = oldConfigurationKeys.filter { propKey in
      !newConfigurationKeys.contains(propKey)
    }
    for propKey in configurationToRestore {
      config.appliedConfiguration[propKey]?.restore(view: view)
    }
    for propKey in newConfigurationKeys {
      viewProperties[propKey]?.assign(view: view, state: _state, props: props, size: bounds)
    }

    if view.yoga.isEnabled, view.yoga.isLeaf, view.yoga.isIncludedInLayout {
      //if !(view is AnyUIComponentView) {
        view.frame.size = .zero
        view.yoga.markDirty()
      //}
    }
    didLayout(options: options)
  }

  /// Re-applies the configuration for the node and compute its layout.
  public func layout(in bounds: CGSize, options: [UINodeOption] = []) {
    assert(Thread.isMainThread)
    _configure(in: bounds, options: options)

    // Compute the flexbox layout for the node.
    let view = requireRenderedView()

    view.bounds.size = bounds
    view.yoga.applyLayout(preservingOrigin: false)
    view.bounds.size = view.yoga.intrinsicSize

    view.yoga.applyLayout(preservingOrigin: false)
    view.frame.normalize()
  }

  private func requireRenderedView() -> UIView {
    guard let view = renderedView else {
      print("Unexpected error: The view is nil.")
      fatalError()
    }
    return view
  }

  private func willLayout(options: [UINodeOption]) {
    let view = requireRenderedView()
    if options.contains(.preventDelegateCallbacks) {
      // Notify the delegate.
      delegate?.nodeWillLayout(self, view: view)
      nodeWillLayout(self, view: view)
    }
  }

  private func didLayout( options: [UINodeOption]) {
    let view = requireRenderedView()
    // Apply some view-specific configuration (e.g. content insets for scrollviews).
    if let UIPostRenderingView = view as? UIPostRendering {
      UIPostRenderingView.postRender()
    }
    if options.contains(.preventDelegateCallbacks) {
      // Notify the delegate.
      delegate?.nodeDidLayout(self, view: view)
      nodeDidLayout(self, view: view)
    }

    /// The view has been newly created.
    if shouldInvokeDidMount {
      shouldInvokeDidMount = false
      delegate?.nodeDidMount(self, view: view)
      self.nodeDidMount(self, view: view)
    }
  }

  /// Asks the node to build the backing view for this node.
  public func _build(with reusableView: UIView? = nil) {
    assert(Thread.isMainThread)
    defer {
      bindIfNecessary(renderedView!)
    }
    guard renderedView == nil else { return }
    if let reusableView = reusableView as? V {
      reusableView.configuration.node = self
      renderedView = reusableView
    } else {
      let view = create()
      shouldInvokeDidMount = true
      view.yoga.isEnabled = true
      view.tag = reuseIdentifier.hashValue
      view.hasNode = true
      view.configuration.node = self
      renderedView = view
    }
  }

  /// Reconciliation algorithm for the view hierarchy.
  private func _reconcile(node: UINodeProtocol, size: CGSize, view: UIView?, parent: UIView) {
    // The candidate view is a good match for reuse.
    if let view = view, view.hasNode && view.tag == node.reuseIdentifier.hashValue {
      node._build(with: view)
      view.configuration.isNewlyCreated = false
    } else {
      // The view for this node needs to be created.
      view?.removeFromSuperview()
      node._build(with: nil)
      node.renderedView!.configuration.isNewlyCreated = true
      parent.insertSubview(node.renderedView!, at: node.index)
    }

    // Gets all of the existing subviews.
    var oldSubviews = view?.subviews.filter { view in
      return view.hasNode
    }

    for subnode in node.children {
      // Look for a candidate view matching the node.
      let candidateView = oldSubviews?.filter { view in
        return view.tag == subnode.reuseIdentifier.hashValue
      }.first

      // Pops the candidate view from the collection.
      oldSubviews = oldSubviews?.filter {
        view in view !== candidateView
      }

      // Recursively reconcile the subnode.
      _reconcile(node: subnode, size: size, view: candidateView, parent: node.renderedView!)
    }

    // Remove all of the obsolete old views that couldn't be recycled.
    for view in oldSubviews ?? [] {
      view.removeFromSuperview()
    }
  }

  /// Mount the component in the view hierarchy by running its reconciliation algorithm.
  /// This means that only the required changes to the view hierarchy are going to be applied.
  public func reconcile(in view: UIView? = nil, size: CGSize? = nil, options: [UINodeOption] = []) {
    assert(Thread.isMainThread)
    guard let view = view ?? renderedView?.superview else {
      return
    }
    let size = size ?? view.bounds.size
    let startTime = CFAbsoluteTimeGetCurrent()
    _reconcile(node: self, size: size, view: view.subviews.first, parent: view)
    layout(in: size, options: [.preventDelegateCallbacks])
    layout(in: size)

    debugReconcileTime("\(Swift.type(of: self)).reconcile", startTime: startTime)
  }

  /// Recursively look for the first non-nil mutator in the hierarchy.
  public func _findMutatorRecursive<M: UINodeDelegateProtocol>() -> M? {
    if let mutator = delegate as? M {
      return mutator
    }
    if parent == nil {
      return nil
    }
    return parent?._findMutatorRecursive()
  }

  // Binding closure.
  private var bindIfNecessary: (UIView) -> Void = { _ in }

  /// Binds the node rendered view to a target property.
  public func bindView<N: UINodeProtocol, V>(target: N,
                                             keyPath: ReferenceWritableKeyPath<N, V>) {
    assert(Thread.isMainThread)
    bindTarget = target
    bindIfNecessary = { [weak self] (view: UIView) in
      guard let view = view as? V, let target = self?.bindTarget as? N else {
        return
      }
      target[keyPath: keyPath] = view
    }
  }

  /// The view got rendered and added to the view hierarchy.
  open func nodeDidMount(_ node: UINodeProtocol, view: UIView) {

  }

  /// The view is about to be layed out.
  open func nodeWillLayout(_ node: UINodeProtocol, view: UIView) {

  }

  /// The view just got layed out.
  open func nodeDidLayout(_ node: UINodeProtocol, view: UIView) {

  }
}

open class UIProplessNode<V: UIView>: UINode<V, UINilState, UINilNodeProps> { }

open class UIStatelessNode<V: UIView, P: UINodePropsProtocol>: UINode<V, UINilState, P> { }

open class UIStatefulNode<V: UIView, S: UIStateProtocol, P: UINodePropsProtocol>: UINode<V, S, P> {

  /// The state for this node.
  public var state: S {
    get {
      return self._state as! S
    }
    set {
      self._state = newValue
      render()
    }
  }

  @available(*, unavailable)
  public override init(reuseIdentifier: String = String(describing: V.self),
                       create: @escaping () -> V = { V() },
                       props: P = P()) {
    fatalError("Initialization not supported.")
  }
  public init(reuseIdentifier: String = String(describing: V.self),
              key: String,
              create: @escaping () -> V = { V() },
              props: P = P()) {
    super.init(reuseIdentifier: reuseIdentifier,
               create: create,
               props: props)
    self.key = key
    let state: S = UIStatePool.default.state(key: key)
    self._state = state
  }
}

// MARK: - Empty Node

public class UINilNode: UINode<UIView, UINilState, UINilNodeProps> {
  static let `nil` = UINilNode()
  public init() {
    super.init(reuseIdentifier: "nil_node")
  }
}

// MARK: - Options

public enum UINodeOption: Int {
  case none
  case preventDelegateCallbacks
}

func debugReconcileTime(_ label: String, startTime: CFAbsoluteTime, threshold: CFAbsoluteTime = 16){
  let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

  // - Note: 60fps means you need to render a frame every ~16ms to not drop any frames.
  // This is even more important when used inside a cell.
  if timeElapsed > threshold  {
    print(String(format: "\(label) (%2f) ms.", arguments: [timeElapsed]))
  }
}
