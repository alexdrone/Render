import Foundation
import UIKit

// MARK: - Node protocol

public protocol NodeType: class {

  /// The underlying view rendered from the node.
  var renderedView: UIView? { get }

  /// The reuse identifier for this node is its hierarchy.
  /// Identifiers help Render understand which items have changed, are added, or are removed.
  var key: Key { get set }

  /// The subnodes of this node.
  var children: [NodeType] { get set }

  /// Adds the nodes passed as argument as subnodes.
  @discardableResult func add(children: [NodeType]) -> NodeType

  /// Internal use only.
  /// This component is the n-th children.
  var index: Int { get set }

  /// The generic type as string.
  var debugType: String { get }

  /// Re-applies the configuration closures recursively and compute the new layout for the
  /// derived associated view hierarchy.
  /// - note: The rencociliation is perfomed from ComponentView owning this node hierarchy.
  func layout(in bounds: CGSize)

  /// Internal use only.
  /// Configure the backing view of this node.
  func configure(in bounds: CGSize)

  /// Pre-render callback.
  func willLayout()

  /// Post-render callback.
  func didLayout()

  /// Asks the node to build the backing view for this node.
  func build(with reusable: UIView?)

  /// Internal use only.
  /// The associated component (if applicable).
  weak var associatedComponent: AnyComponentView? { get set }
}

// MARK: - Implementation

public class Node<V: UIView>: NodeType {

  public typealias CreateBlock = () -> V
  public typealias PropsBlock = (V, YGLayout, CGSize) -> (Void)
  public typealias OnLayoutBlock = (V?) -> (Void)

  /// The underlying view rendered from the node.
  public private(set) var renderedView: UIView? {
    get { return view }
    set { view = newValue as? V }
  }
  public private(set) var view: V?

  /// The unique identifier of this node is its hierarchy.
  /// Choosing a good identifier is foundamental for good and performant view recycling.
  /// Identifiers help Render understand which items have changed, are added, or are removed.
  public var key: Key

  /// When this property is true the associated view will get reset to its original state before
  /// being reconfigured.
  /// Targets for UIControl get reset anyway.
  public let resetBeforeReuse: Bool

  /// Pre/Post render callbacks.
  public var onRender: (will: OnLayoutBlock?, did: OnLayoutBlock?) = (nil, nil)

  /// The configuration block for this node.
  private let props: PropsBlock

  /// The initialization block for this node.
  /// This is the perfect entry point for the configuration code that is intended to be run
  /// exactly once (at view creation time).
  /// - note: Remember to have a unique reuse identifier set for this node if you have a custom
  /// initialization closure.
  private let create: CreateBlock

  /// This is the n-th child.
  public var index: Int = 0

  /// The generic type as string.
  public let debugType: String

  /// The associated component (if applicable).
  public weak var associatedComponent: AnyComponentView?

  /// The current children for this node.
  public var children: [NodeType] = [] {
    didSet {
      var index = 0
      children = children.filter { child in !(child is NilNode) }
      for child in children where !(child is NilNode) {
        child.index = index
        index += 1
      }
    }
  }

  /// Adds the nodes passed as argument as subnodes.
  @discardableResult public func add(children: [NodeType]) -> NodeType {
    let nodes = children.filter { node in !(node is NilNode) }
    self.children += nodes
    return self
  }

  /// Adds the node passed as argument as subnode.
  @discardableResult public func add(child: NodeType) -> NodeType {
    guard !(child is NilNode) else {
      return self
    }
    children = children + [child]
    return self
  }

  /// Construct a new Node hierarchy.
  /// - parameter key: The reuse identifier for this node is its hierarchy.
  /// - parameter resetBeforeReuse: When this property is true the associated view will get reset
  /// to its original state before being reconfigured.
  /// - parameter children: (Optional) children for this node.
  /// - parameter create: The initialization block for this node.
  /// This is the perfect entry point for the configuration code that is intended to be run
  /// exactly once (at view creation time).
  /// Remember to have a unique reuse identifier set for this node if you have a custom
  /// initialization closure.
  /// - parameter configure: The closure that is going to be executed every time this node
  /// will re-render.
  public init(reuseIdentifier: String = String(describing: V.self),
              key: String = "",
              resetBeforeReuse: Bool = false,
              children: [NodeType] = [],
              create: @escaping CreateBlock = { V() },
              props: @escaping PropsBlock = { _ in }) {
    self.key = Key(reuseIdentifier: reuseIdentifier, key: key)
    self.resetBeforeReuse = resetBeforeReuse
    self.create = create
    self.props = props
    self.children = children
    self.debugType = String(describing: V.self)
  }

  /// Re-applies the configuration closures recursively and compute the new layout for the
  /// derived associated view hierarchy.
  /// - note: The rencociliation is perfomed from ComponentView owning this node hierarchy.
  public func layout(in bounds: CGSize) {
    assert(Thread.isMainThread)
    configure(in: bounds)
    guard let view = view else {
      fatalError()
    }
    view.bounds.size = bounds
    view.yoga.applyLayout(preservingOrigin: false)
    view.bounds.size = view.yoga.intrinsicSize  
    view.yoga.applyLayout(preservingOrigin: false)
  }

  /// Configure the backing view of this node.
  public func configure(in bounds: CGSize) {
    build()
    willLayout()
    for child in children {
      child.configure(in: bounds)
    }
    guard let view = view else {
      return
    }
    props(view, view.yoga, bounds)
    if view.yoga.isEnabled, view.yoga.isLeaf, view.yoga.isIncludedInLayout {
      if !(view is AnyComponentView) {
        // UIView reports its current size as the content size.
        // This is done to make sure that empty views don't show up.
        view.frame.size = .zero
        view.yoga.markDirty()
      }
    }
    didLayout()
  }

  /// Pre-render callback.
  public func willLayout() {
    if resetBeforeReuse {
      view?.flushGestureRecognizersRecursively()
      view?.prepareForComponentReuse()
      view?.tag = key.reuseIdentifier.hashValue
    }
    if let view = self.view {
      // If the view passed as argument is a UIControl this resets all the pre-existents targets.
      Reset.resetTargets(view)
      onRender.will?(view)
    }
  }

  /// Post-render callback.
  public func didLayout() {
    if let postRenderingView = view as? PostRendering {
      postRenderingView.postRender()
    }
    if let view = view {
      onRender.did?(view)
    }
  }

  /// Constructs a new view for this node or recycle the one passed as argument.
  public func build(with reusable: UIView? = nil) {
    guard view == nil else { return }
    if let reusable = reusable as? V {
      view = reusable
    } else {
      view = create()
      view?.yoga.isEnabled = true
      view?.tag = key.reuseIdentifier.hashValue
      view?.hasNode = true
    }
  }
}

// MARK: - Nested components

/// Used to wrap nested components in the Node hierarchy.
/// - parameter type: The component class for this node.
/// - parameter root: Likely the component that is calling the 'render' method.
/// - parameter baseKey: The key of the parent node. (Important if you have several components of
/// the same kind at different level of your hierarchy).
/// - parameter key: Keys help Render identify which items have changed, are added, or are removed.
/// Keys should be given to the elements inside the array to give the elements a stable identity
/// - parameter state: The state for the component. (If nil is passed as argument the previous state
/// of the component will be reapplied to the component).
/// - paramenter size: The bounds for the parent component.
/// - paramenter props: Configuration closure for the component proprieties.
public func ComponentNode<T: ComponentViewType>(_ component: @autoclosure () -> T,
                                                in rootComponent: AnyComponentView,
                                                reuseIdentifier: String = String(describing:T.self),
                                                key: String? = nil,
                                                state: StateType? = nil,
                                                size: ((AnyComponentView?) -> CGSize)? = nil,
                                                props: ((T, Bool) -> Void)? = nil) -> NodeType {

  // If no key get passed as argument a new autoincrement key is generated.
  // This autoincrement key is calculated by enumerating (at every render pass) the component
  // of the same kind for the same parent component.
  var _key = "\(rootComponent.childrenComponentAutoIncrementKey)"
  if let key = key {
    _key = key
  } else {
    rootComponent.childrenComponentAutoIncrementKey += 1
  }
  let childKey = Key(reuseIdentifier: reuseIdentifier, key: _key)
  let component = (rootComponent.childrenComponent[childKey] as? T) ?? component()
  let componentState = (state as? T.StateType) ?? component.state
  component.rootComponent = rootComponent
  component.state = componentState
  component.referenceSize = size ?? rootComponent.referenceSize
  component.key = childKey
  
  // Applies the component configuration (this would be the props in the react world).
  props?(component, rootComponent.childrenComponent[childKey] == nil)
  rootComponent.childrenComponent[childKey] = component

  let node = component.render()
  node.key = childKey
  node.associatedComponent = component

  return node
}

// MARK: - Nil Implementation

/// A node withouth a backing view.
public final class NilNode: NodeType {

  public lazy var renderedView: UIView? = {
    let view = UIView(frame: CGRect.zero)
    view.hasNode = true
    view.tag = self.key.reuseIdentifier.hashValue
    return view;
  }()
  public var key: Key = Key(reuseIdentifier: String(describing: NilNode.self))
  public var children: [NodeType] = []
  public func add(children: [NodeType]) -> NodeType { return self }
  public var index: Int = 0
  public let debugType: String = "Nil"
  public weak var associatedComponent: AnyComponentView?

  public init() { }
  public func layout(in bounds: CGSize) { }
  public func configure(in bounds: CGSize) { }
  public func willLayout() { }
  public func didLayout() { }
  public func build(with reusable: UIView?) { }
}

// MARK: - Key

public struct Key: Hashable, Equatable {
  public internal(set) var reuseIdentifier: String
  public internal(set) var key: String

  public var stringValue: String {
    return "\(reuseIdentifier)_\(key)"
  }

  public var hashValue: Int {
    return stringValue.hashValue
  }

  public static func ==(lhs: Key, rhs: Key) -> Bool {
    return lhs.stringValue == rhs.stringValue
  }

  public init(reuseIdentifier: String = "", key: String = "") {
    self.reuseIdentifier = reuseIdentifier
    self.key = key
  }
}


