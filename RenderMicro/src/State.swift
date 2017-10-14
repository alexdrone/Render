import Foundation

// MARK: - State protocol

/// There are two types of data that control a component: configuration and state.
/// configuration are simply the component proprieties, set by the parent and they are fixed
///  throughout the lifetime of a component.
/// For data that is going to change, we have to use state.
public protocol UIStateProtocol: class, ReflectedStringConvertible {
  /// Returns the initial state for this current state type.
  init()
}

public final class UINilState: UIStateProtocol {
  static let `nil` = UINilState()
  public init() { }
}

open class UIState: UIStateProtocol {
  public required init() { }
}

public final class UIStatePool {
  /// The global pool.
  static let `default` = UIStatePool()
  // Map from key to state currently allocated.
  private var states: [String: UIStateReferenceContainer] = [:]
  // Map from key to the delegate associated to it (if available).
  private var delegates: [String: UINodeDelegateProtocol] = [:]

  /// Fetches or create a new UI state.
  func state<S: UIStateProtocol>(key: String) -> S {
    assert(Thread.isMainThread)
    // Removed the entries that are no longer.
    states = states.filter { _, container in container.state != nil }

    if let container = states[key] {
      if let state = container.state as? S {
        return state
      } else {
        fatalError("Another state with the same key has already been allocated.")
      }
    }
    let state = S()
    states[key] = UIStateReferenceContainer(state: state)
    return state
  }

}

final class UIStateReferenceContainer {
  private(set) weak var state: UIStateProtocol?

  init(state: UIStateProtocol) {
    self.state = state
  }
}

// MARK: - ReflectedStringConvertible

public protocol ReflectedStringConvertible : CustomStringConvertible {}
extension ReflectedStringConvertible {
  /// Returns a representation of the state in the form:
  /// Type(prop1: 'value', prop2: 'value'..)
  func reflectionDescription(del: String = "") -> String {
    let mirror = Mirror(reflecting: self)
    var str = ""
    var first = true
    for (label, value) in mirror.children {
      if let label = label {
        if first { first = false } else {  str += ", "  }
        str += "\(del)\(label)\(del): \(del)\(value)\(del)"
      }
    }
    return "{ \(str) }"
  }

  /// A textual description of the object.
  public var description: String {
    return reflectionDescription()
  }
}
