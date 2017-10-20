import UIKit

// MARK: - UINodeDelegateProtocol

public protocol UINodeDelegateProtocol: class {
  /// The view got rendered and added to the view hierarchy.
  func nodeDidMount(_ node: UINodeProtocol, view: UIView)
  /// The view is about to be layed out.
  func nodeWillLayout(_ node: UINodeProtocol, view: UIView)
  /// The view just got layed out.
  func nodeDidLayout(_ node: UINodeProtocol, view: UIView)
}

// MARK: - UINodeProtocol

public protocol UINodeProtocol: class {
  /// The underlying rendered view.
  var renderedView: UIView? { get }
  /// The optional delegate for this node.
  weak var delegate: UINodeDelegateProtocol? { get set }
  /// The parent node (if applicable).
  weak var parent: UINodeProtocol? { get set }
  /// This must be defined if the node is a stateful node.
  /// It uniquely defines a node.
  var key: String? { get set }
  /// The reuse identifier for this node is its hierarchy.
  /// Identifiers help Render understand which items have changed.
  var reuseIdentifier: String { get }
  /// The subnodes of this node.
  var children: [UINodeProtocol] { get }
  /// This component is the n-th children.
  var index: Int { get set }
  /// Re-applies the configuration for the node and compute its layout.
  func layout(in bounds: CGSize, options: [UINodeOption])
  /// Mount the component in the view hierarchy by running its reconciliation algorithm.
  /// This means that only the required changes to the view hierarchy are going to be applied.
  func reconcile(in view: UIView?, size: CGSize?, options: [UINodeOption])

  // Internal.

  /// Asks the node to build the backing view for this node.
  func _constructView(with reusableView: UIView?)
  /// Configure the backing view of this node.
  func _setup(in bounds: CGSize, options: [UINodeOption])
}

// MARK: - UINode

public class UINode<V: UIView>: UINodeProtocol {

  public struct Layout {
    /// The associated node for this layout pass.
    public internal(set) var node: UINode<V>
    /// The concrete view associated to this node.
    public internal(set) var view: V
    /// The canvas size for the root componens.
    public internal(set) var canvasSize: CGSize

    init(node: UINode<V>, view: V, size: CGSize) {
      self.node = node
      self.view = view
      self.canvasSize = size
    }

    public func set<T>(_ keyPath: ReferenceWritableKeyPath<V, T>,
                       animator: UIViewPropertyAnimator? = nil,
                       value: T) {
      node.viewProperties[keyPath.hashValue] =
          UIViewKeyPathValue(keyPath: keyPath, value: value, animator: animator)
    }
  }

  public typealias UINodeCreationClosure = () -> V
  public typealias UINodeConfigurationClosure = (Layout) -> Void
  public typealias UINodeChildrenCreationClosure = (Layout) -> [UINodeProtocol]

  public let isStateless: Bool = true

  public fileprivate(set) var renderedView: UIView? = nil
  public var delegate: UINodeDelegateProtocol?
  public weak var parent: UINodeProtocol?

  // Since there's no state, there's no key for this component.
  public var key: String? = nil
  public fileprivate(set) var reuseIdentifier: String

  public fileprivate(set) var children: [UINodeProtocol] = []
  public var index: Int = 0

  // The creation closure for the view.
  private let createClosure: UINodeCreationClosure
  private var configClosure: UINodeConfigurationClosure = { _ in }
  private var childrenClosure: UINodeConfigurationClosure = { _ in }

  private var shouldInvokeDidMount: Bool = false
  private weak var bindTarget: AnyObject?

  // The properties for this node.
  var viewProperties: [Int: UIViewKeyPathValue] = [:]

  public init(reuseIdentifier: String = String(describing: V.self),
              key: String? = nil,
              create: (() -> V)? = nil,
              configure: UINodeConfigurationClosure? = nil) {
    self.reuseIdentifier = reuseIdentifier
    self.createClosure = create ??  { V() }
    if create != nil && reuseIdentifier == String(describing: V.self) {
      fatalError("Always specify a reuse identifier whenever a custom create closure is provided.")
    }
    self.key = key
    if let configure = configure {
      self.configClosure = configure
    }
  }

  open func configure(_ configClosure: @escaping UINodeConfigurationClosure) {
    self.configClosure = configClosure
  }

  /// Sets the subnodes of this node.
  @discardableResult public func children(_ children: [UINodeProtocol]) -> Self {
    var nodes = children
    var index = 0
    for child in children {
      child.index = index
      child.parent = self
      nodes.append(child)
      index += 1
    }
    self.children = nodes
    return self
  }

  /// Configure the backing view of this node.
  public func _setup(in bounds: CGSize, options: [UINodeOption]) {
    assert(Thread.isMainThread)
    _constructView()
    willLayout(options: options)

    let view = requireRenderedView()
    guard let renderedView = view as? V else {
      print("Unexpected error: View/State/Props type mismatch.")
      return
    }
    let layout = Layout(node: self, view: renderedView, size: bounds)
    configClosure(layout)

    // Configure the children recursively.
    for child in children {
      child._setup(in: bounds, options: options)
    }

    let config = view.renderContext
    let oldConfigurationKeys = Set(config.appliedConfiguration.keys)
    let newConfigurationKeys = Set(viewProperties.keys)

    let configurationToRestore = oldConfigurationKeys.filter { propKey in
      !newConfigurationKeys.contains(propKey)
    }
    for propKey in configurationToRestore {
      config.appliedConfiguration[propKey]?.restore(view: view)
    }
    for propKey in newConfigurationKeys {
      viewProperties[propKey]?.assign(view: view)
    }

    if view.yoga.isEnabled, view.yoga.isLeaf, view.yoga.isIncludedInLayout {
      view.frame.size = .zero
      view.yoga.markDirty()
    }
    didLayout(options: options)
  }

  /// Re-applies the configuration for the node and compute its layout.
  public func layout(in bounds: CGSize, options: [UINodeOption] = []) {
    assert(Thread.isMainThread)
    _setup(in: bounds, options: options)

    let view = requireRenderedView()
    viewProperties = [:]

    // Compute the flexbox layout for the node.
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
    }

    /// The view has been newly created.
    if shouldInvokeDidMount {
      shouldInvokeDidMount = false
      delegate?.nodeDidMount(self, view: view)
    }
  }

  /// Asks the node to build the backing view for this node.
  public func _constructView(with reusableView: UIView? = nil) {
    assert(Thread.isMainThread)
    defer {
      bindIfNecessary(renderedView!)
    }
    guard renderedView == nil else { return }
    if let reusableView = reusableView as? V {
      reusableView.renderContext.node = self
      renderedView = reusableView
    } else {
      let view = createClosure()
      shouldInvokeDidMount = true
      view.yoga.isEnabled = true
      view.tag = reuseIdentifier.hashValue
      view.hasNode = true
      view.renderContext.node = self
      renderedView = view
    }
  }

  /// Reconciliation algorithm for the view hierarchy.
  private func _reconcile(node: UINodeProtocol, size: CGSize, view: UIView?, parent: UIView) {
    // The candidate view is a good match for reuse.
    if let view = view, view.hasNode && view.tag == node.reuseIdentifier.hashValue {
      node._constructView(with: view)
      view.renderContext.isNewlyCreated = false
    } else {
      // The view for this node needs to be created.
      view?.removeFromSuperview()
      node._constructView(with: nil)
      node.renderedView!.renderContext.isNewlyCreated = true
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

  // Binding closure.
  private var bindIfNecessary: (UIView) -> Void = { _ in }

  /// Binds the node rendered view to a target property.
  public func bindView<O: AnyObject, V>(target: O,
                                        keyPath: ReferenceWritableKeyPath<O, V>) {
    assert(Thread.isMainThread)
    bindTarget = target
    bindIfNecessary = { [weak self] (view: UIView) in
      guard let object = self?.bindTarget as? O, let view = view as? V else {
        return
      }
      object[keyPath: keyPath] = view
    }
  }
}

// MARK: - UINilNode

/// Represent an empty node.
public class UINilNode: UINode<UIView> {
  /// Static shared instance.
  static let `nil` = UINilNode()

  public init() {
    super.init(reuseIdentifier: "nil_node")
  }
}

// MARK: - UINodeOption

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
