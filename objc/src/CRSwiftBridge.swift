import UIKit

// Convenience type-erased protocols.
public protocol NodeProtocol: class { }
public protocol ControllerProtocol: class {}
@objc public protocol PropsProtocol: class {}

extension ConcreteNode: NodeProtocol { }
extension Controller: ControllerProtocol { }
extension Props: PropsProtocol { }

/// Swift-only extensions.
public extension NodeProtocol {
  /// Adds the nodes as children of this node.
  @discardableResult public func append(children: [NodeProtocol]) -> ConcreteNode<UIView> {
    let node = self as! ConcreteNode<UIView>
    let children = children.compactMap { $0 as? ConcreteNode<UIView> }
    node.appendChildren(children)
    return node
  }
}

/// Creates a new *CRNode*.
/// - parameter reuseIdentifer: The reuse identifier for this node is its hierarchy.
/// Identifiers help Render understand which items have changed.
/// A custom *reuseIdentifier* is mandatory if the node has a custom creation closure.
/// - parameter key:  A unique key for the component/node (necessary if the associated
/// component is stateful).
/// - parameter create: Custom view initialization closure.
/// - parameter layoutSpec: This closure is invoked whenever the 'layout' method is invoked.
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
@inline(__always)
public func Node<V: UIView> (
  type: V.Type,
  props: PropsProtocol? = nil,
  reuseIdentifier: String? = nil,
  key: String? = nil,
  create: (() -> V)? = nil,
  layoutSpec: @escaping (LayoutSpec<V>) -> Void
) -> ConcreteNode<V> {
  return ConcreteNode<V>(
    type: V.self,
    props: props as? Props,
    reuseIdentifier: reuseIdentifier,
    key: key,
    viewInitialization: create,
    layoutSpec: layoutSpec)
}

@inline(__always)
public func set<V: UIView, T>(
  _ spec: LayoutSpec<V>,
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

public typealias LayoutOptions = CRNodeLayoutOptions
