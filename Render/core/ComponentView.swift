import Foundation
import UIKit

// MARK: - State protocol

/// There are two types of data that control a component: props and state.
/// props are simply the component proprieties,  set by the parent and they are fixed throughout the
/// lifetime of a component.
/// For data that is going to change, we have to use state.
public protocol StateType {
  /// Returns the initial state for this current state type.
  init()
}

/// Represent a empty state (for components that don't need a state).
public struct NilState: StateType {
  public init() { }
}

public enum RenderOption {
  /// The 'render' method is called just once.
  /// This means that render will simply re-apply the existing configuration for the nodes
  /// and compute the new layout accordingly.
  ///  This is a very useful optimisation for components with a static view hierarchy.
  case preventViewHierarchyDiff

  /// Animates the layout changes.
  case animated(duration: TimeInterval, options: UIViewAnimationOptions)

  /// Prevents the component from render.
  case preventUpdate

  /// Prevents the onLayout registered callback to be invoked at this very render pass.
  case preventOnLayoutCallback

  // Internal use only.
  case __animated
  case __none
}

// MARK: - ComponentView protocol

public protocol AnyComponentView: class {

  /// Stateless component are components that are expected to be fully configured from the outside
  /// without mantaining an internal state.
  /// Stateless components offers better performance and memory footprint because they can be more
  /// easily recycled.
  /// See 'StatelessComponentView'.
  var isStateless: Bool { get }

  /// Internal use only.
  /// Used a store for nested component view refs.
  var childrenComponent: [Key: AnyComponentView] { get set }

  /// Internal use only.
  var childrenComponentAutoIncrementKey: Int  { get set }

  /// Called whenever the component is laying out iteself.
  /// Usually you'd want your UIViewController to position the component view in its view
  /// hierarchy.
  var onLayoutCallback: (TimeInterval, AnyComponentView, CGSize) -> () { get set }

  /// This will run 'render' that generates a new virtual-tree for this component.
  /// The tree is then diffed against the current one and the changes are applied to current
  /// view hierarchy.
  /// The layout for the resulting view hierarchy is then re-computed.
  func update(options: [RenderOption])

  /// Asks the view to calculate and return the size that best fits the specified size.
  func sizeThatFits(_ size: CGSize) -> CGSize

  /// The natural size for the receiving view, considering only properties of the view itself.
  var intrinsicContentSize : CGSize { get }

  /// Sets the component state.
  func set(state: Render.StateType, options: [RenderOption])

  init()

  /// This method is called during the layout transaction.
  /// If an animation is ongoing the duration is going to be > 0.
  /// This is the entry point for custom manual layout of node that have 'yoga.isIncludedInLayout'
  /// set to 'false'.
  func onLayout(duration: TimeInterval)

  /// Called whenever the component is about to be updated and re-rendered.
  func willUpdate()

  /// Called whenever the component has been rendered and installed on the screen.
  func didUpdate()

  /// The component bounds.
  var referenceSize: () -> CGSize { get set }

  /// Geometry
  var rootView: UIView! { get }
  var frame: CGRect { get set }
  var center: CGPoint { get set }
  var bounds: CGRect { get set }

  /// If the component is wrapped into a cell this will have a ref to it.
  weak var associatedCell: ComponentCellType? { get set }

  // Internal
  var identityMapForListNode: [Key: [Key]] { get set }
}

public protocol ComponentViewType: AnyComponentView {

  associatedtype StateType

  var state: StateType { get set }

  /// The 'render' method is required.
  /// When called, it should examine the component properties and the state  and return a Node tree.
  /// This method is called every time 'render' is invoked.
  func render() -> NodeType
}

public extension ComponentViewType {

  /// Sets the component state.
  func set(state: Render.StateType, options: [RenderOption] = []) {
    guard let state = state as? Self.StateType else {
      return
    }
    self.state = state
    if !RenderOption.contains(options, .preventUpdate) {
      update(options: options)
    }
  }
}

// MARK: - Implementation

/// Components let you split the UI into independent, reusable pieces, and think about each
/// piece in isolation.
/// A component represents a function that maps a state S to its representation.
/// The infrastructure below takes care of applying the minimal set of diffs whenever it is
/// necessary.
open class ComponentView<S: StateType>: UIView, ComponentViewType {

  public typealias StateType = S
  public typealias RenderBlock = (S, CGSize) -> NodeType

  /// The state of the component. Call 'render' on this component after the new state is set.
  public var state: S = S()

  public fileprivate(set) var isStateless: Bool = false

  /// The bounding rect of the component (the maximum size).
  public lazy var referenceSize: () -> CGSize = {
    return self.boundingRect
  }()

  public var onLayoutCallback: (TimeInterval, AnyComponentView, CGSize) -> () = { _ in }

  private func boundingRect() -> CGSize {
    if let cell = associatedCell {
      return cell.referenceSize()
    } else {
      return self.superview?.bounds.size ?? CGSize.zero
    }
  }

  public func setState(options: [RenderOption] = [], change: (inout S) -> (Void)) {
    change(&self.state)
    if !RenderOption.contains(options, .preventUpdate) {
      update(options: options)
    }
  }

  /// The component's default options.
  public var defaultOptions: [RenderOption] = []

  /// The reuse identifier of the root node for this component.
  public var key: Key {
    return root.key
  }

  /// Alternative to subclassing ComponentView.
  public var renderBlock: RenderBlock?

  /// The (current) root node.
  private var root: NodeType = NilNode()

  /// The (current) view associated to the root node.
  public private(set) var rootView: UIView!
  private lazy var contentView: UIView = {
    return UIView()
  }()

  /// Wether the 'root' node has been rendered yet.
  private var initialized: Bool = false

  /// Store for the chilren component view.
  /// Keys in the store help identify which items have changed, are added, or are removed.
  /// Keys should be given to the elements inside the array to give the elements a stable identity
  public var childrenComponent: [Key: AnyComponentView] = [:]

  /// Internal use only.
  public var childrenComponentAutoIncrementKey: Int = 0

  /// Internal use only.
  public var identityMapForListNode: [Key: [Key]] = [:]
  public weak var associatedCell: ComponentCellType? 

  public required init() {
    super.init(frame: CGRect.zero)
    commonInit()
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  private func commonInit() {
    rootView = root.renderedView
    addSubview(contentView)
    let notification = Notification.Name("INJECTION_BUNDLE_NOTIFICATION")
    NotificationCenter.default.addObserver(forName: notification,
                                           object: nil,
                                           queue: nil) { [weak self] _ in
      self?.update()
    }
  }

  /// The 'render' method is required for subclasses.
  /// When called, it should examine the component properties and the state  and return a Node tree.
  /// This method is called every time 'render' is invoked.
  open func render() -> NodeType {
    if let renderBlock = renderBlock {
      return renderBlock(state, referenceSize())
    } else {
      return NilNode()
    }
  }

  /// This will run 'render' that generates a new virtual-tree for this component.
  /// The tree is then diffed against the current one and the changes are applied to current
  /// view hierarchy.
  /// The layout for the resulting view hierarchy is then re-computed.
  public func update(options: [RenderOption] = []) {
    assert(Thread.isMainThread)
    if RenderOption.contains(options, .preventUpdate) {
      return
    }
    let size = self.referenceSize()
    willUpdate()
    let startTime = CFAbsoluteTimeGetCurrent()

    let numberOfPasses = 1
    for idx in 0..<numberOfPasses {
      let passOptions = idx != 0 ? options + [.preventViewHierarchyDiff] : options
      internalUpdate(in: size, options: passOptions)
    }

    debugReconcileTime("\(type(of: self)).render", startTime: startTime)
    didUpdate()
  }

  open func onLayout(duration: TimeInterval) { }

  // Internal render method.
  private func internalUpdate(in bounds: CGSize = CGSize.max, options: [RenderOption]) {
    var opts = defaultOptions + options

    // At the first execution of 'render' the view cannot be animated.
    if !initialized {
      opts = RenderOption.filter(opts, .__animated)
    }

    // Rerenders the tree and computes the diff.
    if !initialized || !RenderOption.contains(opts, .preventViewHierarchyDiff) {
      self.childrenComponentAutoIncrementKey = 0
      root = render()
      reconcile(new: root, size: bounds, view: rootView, parent: contentView)
      rootView = root.renderedView!
    }
    initialized = true

    func layout(duration: TimeInterval) {
      // Applies the configuration closures and recursively computes the layout.
      root.layout(in: bounds)

      let yoga = rootView.yoga
      yoga.applyLayout(preservingOrigin: false)

      // Applies the frame to the host view.
      rootView.frame.normalize()
      contentView.frame.size = rootView.bounds.size

      contentView.frame.size.height += yoga.marginTop.normal + yoga.marginBottom.normal
      contentView.frame.size.width +=  yoga.marginLeft.normal + yoga.marginRight.normal
      frame = contentView.bounds

      onLayout(duration: duration)
      if !RenderOption.contains(options, .preventOnLayoutCallback) {
        onLayoutCallback(duration, self, frame.size)
        // Propagates the callback to the cell if necessary.
        if let cell = associatedCell {
          cell.onLayout(duration: duration, component: self, size: frame.size)
        }
      }
    }

    // Lays out the views with an animation.
    if let animation = RenderOption.first(opts, .__animated) {

      // Hides all of the newly created views.
      let newViews: [(UIView, CGFloat)] = views() { view in
        return view.isNewlyCreated && !RenderOption.contains(opts, .preventViewHierarchyDiff)
      }.map { view in
        let result = (view, view.alpha)
        view.alpha = 0
        return result
      }

      switch animation {
        case .animated(let duration, let options):
          UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            layout(duration: duration)
            self.rootView.animateCornerRadiusInHierarchyIfNecessary(duration: duration)
          }) { _ in
            UIView.animate(withDuration: duration/2) {
              for (view, alpha) in newViews {
                view.alpha = alpha
                view.animateCornerRadiusInHierarchyIfNecessary(duration: duration/2)
              }
            }
          }
        default: break
      }
    // Lays out the views.
    } else {
      layout(duration: 0)
    }
  }

  open func willUpdate() {
    // Forwards the 'willMount' method to all of the children compoennts.
    for (_, child) in childrenComponent {
      child.willUpdate()
    }
  }

  open func didUpdate() {
    // Forwards the 'didMount' method to all of the children compoennts.
    for (_, child) in childrenComponent {
      child.didUpdate()
    }
  }

  /// Returns all views (descending recursively through the view hierarchy) that matches the
  /// condition passed as argument.
  public func views(root: UIView? = nil, matching: (UIView) -> Bool) -> [UIView] {
    guard let view: UIView = root ?? rootView else {
      return []
    }
    var result: [UIView] = matching(view) ? [view] : []
    for subview in view.subviews where subview.hasNode {
      result.append(contentsOf: views(root: subview, matching: matching))
    }
    return result
  }

  public func views<T: UIView>(type: T.Type, key: String) -> [T] {
    let _key = Key(reuseIdentifier: String(describing: type), key: key)
    return views { $0.tag == _key.stringValue.hashValue }.flatMap { $0 as? T }
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    update()
  }

  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
  }

  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    assert(Thread.isMainThread)
    update(options: [.preventViewHierarchyDiff, .preventOnLayoutCallback])
    return rootView.yoga.intrinsicSize
  }

  open override var intrinsicContentSize : CGSize {
    assert(Thread.isMainThread)
    return sizeThatFits(CGSize.max)
  }

  /// Reconciliation algorithm for the view hierarchy.
  private func reconcile(new: NodeType, size: CGSize, view: UIView?, parent: UIView) {
    assert(Thread.isMainThread)

    // The candidate view is a good match for reuse.
    if let view = view, view.hasNode && view.tag == new.key.hashValue {
      new.build(with: view)
      view.isNewlyCreated = false
    // The view for this node needs to be created.
    } else {
      view?.removeFromSuperview()
      new.build(with: nil)
      new.renderedView!.isNewlyCreated = true
      parent.insertSubview(new.renderedView!, at: new.index)
    }
    // Gets all of the existing subviews.
    var oldSubviews = view?.subviews.filter { view in
      return view.hasNode
    }

    for subnode in new.children {
      // Look for a candidate view matching the node.
      let candidateView = oldSubviews?.filter { view in
        return view.tag == subnode.key.hashValue
      }.first
      // Pops the candidate view from the collection.
      oldSubviews = oldSubviews?.filter {
        view in view !== candidateView
      }
      // Recursively reconcile the subnode.
      reconcile(new: subnode, size: size, view: candidateView, parent: new.renderedView!)
    }

    // Remove all of the obsolete old views that couldn't be recycled.
    for view in oldSubviews ?? [] {
      view.removeFromSuperview()
    }
  }
}

/// Stateless component are components that are expected to be fully configured from the outside
/// without mantaining an internal state.
/// You're expected to pass the events to the owner (ideally a UIViewController or a non-stateless
/// ComponentView).
/// Stateless components offers better performance and memory footprint because they can be more
/// easily recycled.
open class StatelessComponent: ComponentView<NilState> {

  public required init() {
    super.init()
    isStateless = true
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    isStateless = true
  }

  public convenience init(render: @escaping RenderBlock) {
    self.init()
    self.renderBlock = render
  }
}

// MARK: - Utilities

func debugReconcileTime(_ label: String, startTime: CFAbsoluteTime, threshold: CFAbsoluteTime = 16){
  let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime)*1000

  // - Note: 60fps means you need to render a frame every ~16ms to not drop any frames.
  // This is even more important when used inside a cell.
  if timeElapsed > threshold  {
    print(String(format: "\(label) (%2f) ms.", arguments: [timeElapsed]))
  }
}

// MARK: Equatable Options

extension RenderOption: Equatable {

  /** Strips the param out of the enum type. */
  public var kind: Int {
    switch self {
    case .preventViewHierarchyDiff: return 1 << 0
    case .animated(_), .__animated: return 1 << 1
    case .preventUpdate: return 1 << 2
    case .preventOnLayoutCallback: return 1 << 3
    case .__none: return 1 << 4
    }
  }

  /** Makes sure the enum is comparable. */
  public static func ==(lhs: RenderOption, rhs: RenderOption) -> Bool {
    return lhs.kind == rhs.kind
  }

  public static func filter(_ options: [RenderOption], _ option: RenderOption) -> [RenderOption] {
    return options.filter { opt in
      return opt == option
    }
  }

  public static func contains(_ options: [RenderOption], _ option: RenderOption) -> Bool {
    return RenderOption.filter(options, option).count > 0
  }

  public static func contains(_ options: [RenderOption], _ subset: [RenderOption]) -> Bool {
    return subset.map({ RenderOption.contains(options, $0) }).reduce(true, { $0 && $1 })
  }

  public static func first(_ options: [RenderOption], _ option: RenderOption) -> RenderOption? {
    return RenderOption.filter(options, option).first
  }
}

