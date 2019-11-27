import Foundation
import UIKit
import CoreRenderObjC

// MARK: - Component

/// A piece of user interface.
/// This is a transient object that represent the description of a particulat subtree at a
/// given state.
///
/// You create custom views by declaring types that conform to the `Component`
/// protocol. Implement the required `body` property to provide the content
/// and behavior for your custom view.
public struct Component<C: Coordinator>: OpaqueNodeBuilderConvertible {
  private let context: Context
  private let key: String
  private let props: [AnyProp]
  private let body: (Context, C) -> OpaqueNodeBuilder

  public init(
    context: Context,
    key: String = NSStringFromClass(C.self),
    props: [AnyProp] = [],
    body: @escaping (Context, C) -> OpaqueNodeBuilder
  ) {
    self.context = context
    self.key = key
    self.props = props
    self.body = body
  }

  /// Forward the call to `build` to return the root node for this hierarchy.
  public func builder() -> OpaqueNodeBuilder {
    makeComponent(type: C.self, context: context, key: key, props: props, body: body)
  }
}

/// Pure function builder for `Component`.
public func makeComponent<C: Coordinator>(
  type: C.Type,
  context: Context,
  key: String = NSStringFromClass(C.self),
  props: [AnyProp] = [],
  body: (Context, C) -> OpaqueNodeBuilder
) -> OpaqueNodeBuilder {
  let reuseIdentifier = NSStringFromClass(C.self)
  let coordinator = context.coordinator(CoordinatorDescriptor(type: C.self, key: key)) as! C
  for setter in props {
    setter.apply(coordinator: coordinator)
  }
  return body(context, coordinator)
    .withReuseIdentifier(reuseIdentifier)
    .withCoordinator(coordinator)
}

// MARK: - OpaqueNodeBuilderConvertible

public protocol OpaqueNodeBuilderConvertible {
  func builder() -> OpaqueNodeBuilder
}

extension OpaqueNodeBuilder: OpaqueNodeBuilderConvertible {
  public func builder() -> OpaqueNodeBuilder { self }
}

// MARK: - Function builders

/// Node builder.
///
/// - `withReuseIdentifier`: The reuse identifier for this node is its hierarchy.
/// Identifiers help Render understand which items have changed.
/// A custom *reuseIdentifier* is mandatory if the node has a custom creation closure.
/// - `withKey`:  A unique key for the component/node (necessary if the associated
/// component is stateful).
/// - `withViewInit`: Custom view initialization closure.
/// - `withLayoutSpec`: This closure is invoked whenever the layout is performed.
/// Configure your backing view by using the *UILayout* object (e.g.):
/// ```
/// ... { spec in
///   spec.set(\UIView.backgroundColor, value: .green)
///   spec.set(\UIView.layer.borderWidth, value: 1)
/// ```
/// You can also access to the view directly (this is less performant because the infrastructure
/// can't keep tracks of these view changes, but necessary when coping with more complex view
/// configuration methods).
/// ```
/// ... { spec in
///   spec.view.backgroundColor = .green
///   spec.view.setTitle("FOO", for: .normal)
/// ```
/// - `withCoordinatorDescriptor:initialState.props`: Associates a coordinator to this node.
/// - `build`: Builds the concrete node.
public func Node<V: UIView>(
  _ type: V.Type = V.self,
  @ContentBuilder builder: () -> ChildrenBuilder = ChildrenBuilder.default
) -> NodeBuilder<V> {
  let children = builder().children.compactMap { $0 as? ConcreteNode }
  return NodeBuilder(type: type).withChildren(children)
}

@_functionBuilder
public struct ContentBuilder {
  public static func buildBlock(
    _ nodes: OpaqueNodeBuilderConvertible...
  ) -> ChildrenBuilder {
    return ChildrenBuilder(children: nodes.map { $0.builder().build() })
  }
}

/// Intermediate structure used as a return type from @_ContentBuilder.
public struct ChildrenBuilder {
  /// Default (no children).
  public static let none = ChildrenBuilder(children: [])
  /// Returns an empty builder.
  public static let `default`: () -> ChildrenBuilder = {
    return ChildrenBuilder.none
  }
  /// The wrapped childrens.
  let children: [AnyNode]
}

// MARK: - Props

public protocol AnyProp {
  /// Setup the coordinator with the given prop.
  func apply(coordinator: Coordinator)
}

/// Any custom-defined property in the coordinator, that is not internal state.
public struct Prop<C: Coordinator, V>: AnyProp {
  public typealias CoordinatorType = C
  public let keyPath: ReferenceWritableKeyPath<C, V>
  public let value: V

  public init(_ keyPath: ReferenceWritableKeyPath<C, V>, _ value: V) {
    self.keyPath = keyPath
    self.value = value
  }
  /// Setup the coordinator with the given prop.
  public func apply(coordinator: Coordinator) {
    guard let coordinator = coordinator as? C else { return }
    coordinator[keyPath: keyPath] = value
  }
}

/// Any custom-defined configuration closure for the coordinator.
public struct BlockProp<C: Coordinator, V> {
  public let block: (C) -> Void

  public init(_ block: @escaping (C) -> Void) {
    self.block = block
  }
  /// Setup the coordinator with the given prop.
  public func apply(coordinator: Coordinator) {
    guard let coordinator = coordinator as? C else { return }
    block(coordinator)
  }
}

// MARK: - Property setters

/// Sets the value of a desired keypath using typesafe writable reference keypaths.
/// - parameter spec: The *LayoutSpec* object that is currently handling the view configuration.
/// - parameter keyPath: The target keypath.
/// - parameter value: The new desired value.
/// - parameter animator: Optional property animator for this change.
public func withProperty<V: UIView, T>(
  in spec: LayoutSpec<V>,
  keyPath: ReferenceWritableKeyPath<V, T>,
  value: T,
  animator: UIViewPropertyAnimator? = nil
) -> Void {
  guard let kvc = keyPath._kvcKeyPathString else {
    print("\(keyPath) is not a KVC property.")
    return
  }
  spec.set(kvc, value: value, animator: animator);
}

public func withProperty<V: UIView, T: WritableKeyPathBoxableEnum>(
  in spec: LayoutSpec<V>,
  keyPath: ReferenceWritableKeyPath<V, T>,
  value: T,
  animator: UIViewPropertyAnimator? = nil
) -> Void {
  guard let kvc = keyPath._kvcKeyPathString else {
    print("\(keyPath) is not a KVC property.")
    return
  }
  let nsValue = NSNumber(value: value.rawValue)
  spec.set(kvc, value: nsValue, animator: animator)
}

// MARK: - Alias types

// Drops the YG prefix.
public typealias FlexDirection = YGFlexDirection
public typealias Align = YGAlign
public typealias Edge = YGEdge
public typealias Wrap = YGWrap
public typealias Display = YGDisplay
public typealias Overflow = YGOverflow

public typealias LayoutOptions = CRNodeLayoutOptions

// Ensure that Yoga's C-enums are accessibly through KeyPathRefs.
public protocol WritableKeyPathBoxableEnum {
  var rawValue: Int32 { get }
}

extension YGFlexDirection: WritableKeyPathBoxableEnum { }
extension YGAlign: WritableKeyPathBoxableEnum { }
extension YGEdge: WritableKeyPathBoxableEnum { }
extension YGWrap: WritableKeyPathBoxableEnum { }
extension YGDisplay: WritableKeyPathBoxableEnum { }
extension YGOverflow: WritableKeyPathBoxableEnum { }
