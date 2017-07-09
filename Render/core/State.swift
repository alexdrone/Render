import Foundation

// MARK: - State protocol

/// There are two types of data that control a component: props and state.
/// props are simply the component proprieties,  set by the parent and they are fixed throughout the
/// lifetime of a component.
/// For data that is going to change, we have to use state.
public protocol StateType: ReflectedStringConvertible {
  /// Returns the initial state for this current state type.
  init()
}

/// Represent a empty state (for components that don't need a state).
public struct NilState: StateType {
  public init() { }
  public var description: String { return "" }
}

public protocol ReflectedStringConvertible : CustomStringConvertible {}
extension ReflectedStringConvertible {

  /// Returns a representation of the state in the form:
  /// Type(prop1: 'value', prop2: 'value'..)
  func reflectionDescription(delimiters: String = "") -> String {
    let mirror = Mirror(reflecting: self)
    var str = "{"
    var first = true
    for (label, value) in mirror.children {
      if let label = label {
        if first { first = false } else {  str += ", "  }
        str += "\(delimiters)\(label)\(delimiters): \(delimiters)\(value)\(delimiters)"
      }
    }
    str += "}"
    return str
  }

  public var description: String {
    return reflectionDescription()
  }
}

