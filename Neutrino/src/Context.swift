import UIKit

public protocol UIContextProtocol: class {
  /// Retrieves the state for the key passed as argument.
  /// If no state is registered yet, a new one will be allocated and returned.
  /// - parameter type: The desired *UIState* subclass.
  /// - parameter key: The unique key associated with this state.
  func state<S: UIStateProtocol>(_ type: S.Type, key: String) -> S
  /// Retrieves the component for the key passed as argument.
  /// If no component is registered yet, a new one will be allocated and returned.
  /// - parameter type: The desired *UIComponent* subclass.
  /// - parameter key: The unique key associated with this component.
  /// - parameter props: Configurations and callbacks passed down to the component.
  /// - parameter parent: Optional if the component is not the root node.
  func component<S, P, C: UIComponent<S, P>>(_ type: C.Type,
                                             key: String,
                                             props: P,
                                             parent: UIComponentProtocol?) -> C
  /// Creates a new volatile stateless component.
  /// - parameter type: The desired *UIComponent* subclass.
  /// - parameter props: Configurations and callbacks passed down to the component.
  /// - parameter parent: Optional if the component is not the root node.
  func transientComponent<S, P, C: UIComponent<S, P>>(_ type: C.Type,
                                                      props: P,
                                                      parent: UIComponentProtocol?) -> C
  /// *Optional* the property animator that is going to be used for frame changes in the component
  /// subtree.
  /// - note: This field is auotmatically reset to 'nil' at the end of every 'render' pass.
  var layoutAnimator: UIViewPropertyAnimator? { get set }
  /// The canvas view in which the component will be rendered in.
  weak var canvasView: UIView? { get set }
  // Internal component construction sanity check.
  var _componentInitFromContext: Bool { get}
  /// States and component object pool that guarantees uniqueness of 'UIState' and 'UIComponent'
  /// instances within the same context.
  var pool: UIContextPool { get }
}

// MARK: - UIContext

public class UIContext: UIContextProtocol {
  public let pool = UIContextPool()
  public weak var canvasView: UIView?
  public var _componentInitFromContext: Bool = false

  // The property animator that is going to be used for frame changes in the subtree.
  public var layoutAnimator: UIViewPropertyAnimator?

  public init() { }

  public func state<S: UIStateProtocol>(_ type: S.Type, key: String) -> S {
    return pool.state(key: key)
  }

  public func component<S, P, C: UIComponent<S, P>>(_ type: C.Type,
                                                    key: String,
                                                    props: P = P(),
                                                    parent: UIComponentProtocol? = nil) -> C {
    assert(Thread.isMainThread)
    _componentInitFromContext = true
    let result: C = pool.component(key: key, construct: C(context: self, key: key))
    result.props = props
    result.parent = parent
    _componentInitFromContext = false
    return result
  }

  public func transientComponent<S, P, C: UIComponent<S, P>>(_ type: C.Type,
                                                             props: P = P(),
                                                             parent: UIComponentProtocol?=nil) -> C{
    assert(Thread.isMainThread)
    _componentInitFromContext = true
    let result: C = C(context: self, key: nil)
    result.props = props
    result.parent = parent
    _componentInitFromContext = false
    return result
  }
}

// MARK: - UIContextPool

public final class UIContextPool {
  private var states: [String: UIStateProtocol] = [:]
  private var components: [String: UIComponentProtocol] = [:]

  /// Retrieves or create a new UI state.
  /// - parameter key: The unique key associated with the new state.
  func state<S: UIStateProtocol>(key: String) -> S {
    assert(Thread.isMainThread)
    if let state = states[key] as? S {
      return state
    }
    guard states[key] == nil else {
      fatalError("Another state with the same key has already been allocated (key: \(key)).")
    }
    let state = S()
    states[key] = state
    return state
  }

  /// Registers a new state in the pool.
  /// - parameter key: The unique key associated with the new state.
  /// - parameter state: The state that is going to be stored in this object pool.
  /// - note: If a state with the same key is already memeber of this object pool, it will be
  /// overriden with the new *state* object passed as argument.
  func store(key: String, state: UIStateProtocol) {
    assert(Thread.isMainThread)
    states[key] = state
  }

  /// Retrieves or create a new UI component.
  /// - parameter key: The unique key associated with this component.
  /// - parameter construct: Instructs the pool on how to instantiate the new component in case
  /// this is not already available in this object pool.
  func component<C: UIComponentProtocol>(key: String, construct: @autoclosure () -> C) -> C {
    assert(Thread.isMainThread)
    if let component = components[key] as? C {
      return component
    }
    guard components[key] == nil else {
      fatalError("Another component with the same key has already been allocated (key: \(key)).")
    }
    let component = construct()
    components[key] = component
    return component
  }

  // Gets rid of the obsolete states.
  func flushObsoleteStates(validKeys: Set<String>) {
    assert(Thread.isMainThread)
    states = states.filter { key, _ in validKeys.contains(key) }
    components = components.filter { key, _ in validKeys.contains(key) }
  }
}

// MARK: - UIContextRegistrar

public final class UIContextRegistrar {

}
