import Foundation

// MARK: - State protocol

/// The state is a data structure that starts with a default value when a Component mounts.
/// It may be mutated across time, mostly as a result of user events.
/// A Component manages its own state internally.
/// Besides setting an initial state, it has no business fiddling with the state of its children.
/// You might conceptualize state as private to that component.
public protocol UIStateProtocol: class, ReflectedStringConvertible {
  /// Returns the initial state for this current state type.
  init()
}

public final class UINilState: UIStateProtocol, Codable {
  public static let `nil` = UINilState()
  public init() { }
}

open class UIState: UIStateProtocol {
  public required init() { }
}

// MARK: - ReflectedStringConvertible

public protocol ReflectedStringConvertible : CustomStringConvertible {}
extension ReflectedStringConvertible {
  /// Returns a representation of the state in the form:
  /// Type(prop1: 'value', prop2: 'value'..)
  func reflectionDescription() -> String {
    let mirror = Mirror(reflecting: self)
    var str = ""
    var first = true
    for (label, value) in mirror.children {
      if let label = label {
        if first { first = false } else {  str += ", "  }
        str += "\(label): \(value)"
      }
    }
    return "{ \(str) }"
  }

  /// A textual description of the object.
  public var description: String {
    return reflectionDescription()
  }
}
