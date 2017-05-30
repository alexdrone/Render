import Foundation
import UIKit

// MARK: - Node protocol

public protocol NodeType: class {

  /** The underlying view rendered from the node. */
  var renderedView: UIView? { get }

  /** The unique identifier for this node is its hierarchy. */
  var identifier: String { get }

  /** The subnodes of this node. */
  var children: [NodeType] { get set }

  /** Adds the nodes passed as argument as subnodes. */
  @discardableResult func add(children: [NodeType]) -> NodeType

  /** This component is the n-th children. */
  var index: Int { get set }

  /** Re-applies the configuration closures recursively and compute the new layout for the
   *  derived associated view hierarchy.
   */
  func render(in bounds: CGSize)

  func __configure(in bounds: CGSize)

  /** Pre-render callback. */
  func willRender()

  /** Post-render callback. */
  func didRender()

  /** Force the component to construct the view. */
  func build(with reusable: UIView?)

  weak var __associatedComponent: AnyComponentView? { get set }
}

// MARK: - Implementation

public class Node<V: UIView>: NodeType {

  public typealias CreateBlock = (Void) -> V
  public typealias ConfigureBlock = (V, YGLayout, CGSize) -> (Void)
  public typealias OnRenderBlock = (V?) -> (Void)

  /** The underlying view rendered from the node. */
  public private(set) var renderedView: UIView? {
    get { return view }
    set { view = newValue as? V }
  }
  public private(set) var view: V?

  /** The unique identifier of this node is its hierarchy. 
   *  Choosing a good identifier is foundamental for good and performant view recycling.
   */
  public let identifier: String

  /** When this property is true the associated view will get reset to its original state before
   *  being reconfigured.
   */
  public let resetBeforeReuse: Bool

  /** Pre/Post render callbacks. */
  public var onRender: (will: OnRenderBlock?, did: OnRenderBlock?) = (nil, nil)

  /** The configuration block for this node. */
  private let configure: ConfigureBlock

  /** The initialization block for this node.
   *  This is the perfect entry point for the configuration code that is intended to be run 
   *  exactly once (at view creation time).
   *  - Note: Remember to have a unique identifier set for this node if you have a custom 
   *  initialization closure.
   */
  private let create: CreateBlock

  public var index: Int = 0

  public weak var __associatedComponent: AnyComponentView?

  /** The current children of this node. */
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

  @discardableResult public func add(children: [NodeType]) -> NodeType {
    let nodes = children.filter { node in !(node is NilNode) }
    self.children += nodes
    return self
  }

  @discardableResult public func add(child: NodeType) -> NodeType {
    guard !(child is NilNode) else {
      return self
    }
    children = children + [child]
    return self
  }

  public init(identifier: String = String(describing: V.self),
              resetBeforeReuse: Bool = false,
              children: [NodeType] = [],
              create: @escaping CreateBlock = { V() },
              configure: @escaping ConfigureBlock = { _ in }) {
    self.identifier = identifier
    self.resetBeforeReuse = resetBeforeReuse
    self.create = create
    self.configure = configure
    self.children = children
  }

  public func render(in bounds: CGSize) {
    assert(Thread.isMainThread)
    __configure(in: bounds)
    guard let view = view else {
      fatalError()
    }
    view.bounds.size = bounds
    view.yoga.applyLayout(preservingOrigin: false)
    view.bounds.size = view.yoga.intrinsicSize  
    view.yoga.applyLayout(preservingOrigin: false)
  }

  public func __configure(in bounds: CGSize) {
    build()
    willRender()
    for child in children {
      child.__configure(in: bounds)
    }
    configure(view!, view!.yoga, bounds)
    if let yoga = view?.yoga, yoga.isEnabled && yoga.isLeaf {
      if !(view is ComponentViewType) {
        // UIView reports its current size as the content size.
        // This is done to make sure that empty views don't show up.
        view?.frame.size = .zero
        
        yoga.markDirty()
      }
    }
    didRender()
  }

  public func willRender() {
    if resetBeforeReuse {
      view?.prepareForComponentReuse()
      view?.tag = identifier.hashValue
    }
    if let view = self.view {

      // If the view passed as argument is a UIControl this resets all the pre-existents targets.
      Reset.resetTargets(view)
      onRender.will?(view)
    }
  }

  /** Post-render callback. */
  public func didRender() {
    if let postRenderingView = view as? PostRendering {
      postRenderingView.postRender()
    }
    if let view = view {
      onRender.did?(view)
    }
  }

  /** Constructs a new view for this node or recycle the one passed as argument. */
  public func build(with reusable: UIView? = nil) {
    guard view == nil else { return }
    if let reusable = reusable as? V {
      view = reusable
    } else {
      view = create()
      view?.yoga.isEnabled = true
      view?.tag = identifier.hashValue
      view?.hasNode = true
    }
  }
}

// MARK: - Nested components


/** Used to wrap nested components in the Node hierarchy. */
public func ComponentNode<T: ComponentViewType>(type: T.Type,
                                                in parent: AnyComponentView,
                                                state: T.StateType? = nil,
                                                size: CGSize = CGSize.undefined,
                                                props: ((T) -> Void)? = nil) -> NodeType {
  let component = T()
  component.state = state
  props?(component)
  parent.__children.append(component)

  let node = component.construct(state: state, size: size)
  node.__associatedComponent = component
  return node
}

// MARK: - Nil Implementation

public class NilNode: NodeType {

  public lazy var renderedView: UIView? = {
    let view = UIView(frame: CGRect.zero)
    view.hasNode = true
    view.tag = self.identifier.hashValue
    return view;
  }()
  public var identifier: String = "__nilnode"
  public var children: [NodeType] = []

  public func add(children: [NodeType]) -> NodeType {
    return self
  }

  public var index: Int = 0
  public weak var __associatedComponent: AnyComponentView?

  public init() { }

  public func render(in bounds: CGSize) { }

  public func __configure(in bounds: CGSize) { }

  public func willRender() { }

  public func didRender() { }

  public func build(with reusable: UIView?) { }
}

