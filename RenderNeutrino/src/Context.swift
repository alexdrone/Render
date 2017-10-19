import UIKit

public protocol UIContextProtocol: class {
  /// Identity map for the components states.
  var pool: UIContextPool { get }
  /// Retrieves the state for the key passed as argument.
  func state<S: UIStateProtocol>(_ type: S.Type, key: String) -> S
  /// Retrieves the component for the key passed as argument.
  func component<S, P, C: UIComponent<S, P>>(_ type: C.Type,
                                             key: String,
                                             props: P,
                                             parent: UIComponentProtocol?) -> C
  /// Builds a new volatile stateless component.
  func transientComponent<S, P, C: UIComponent<S, P>>(_ type: C.Type,
                                                      props: P,
                                                      parent: UIComponentProtocol?) -> C

  // Internal sanity check.
  var _componentInitFromContext: Bool { get}
}

public class UIContext: UIContextProtocol {
  public let pool = UIContextPool()
  public var _componentInitFromContext: Bool = false

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

public final class UIContextPool {
  private var states: [String: UIStateProtocol] = [:]
  private var components: [String: UIComponentProtocol] = [:]

  /// Retrieves or create a new UI state.
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
  func store(key: String, state: UIStateProtocol) {
    assert(Thread.isMainThread)
    states[key] = state
  }

  /// Retrieves or create a new UI component.
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
    states = states.filter { key, _ in validKeys.contains(key)}
    components = components.filter { key, _ in validKeys.contains(key)}
  }
}
