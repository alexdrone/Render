import Foundation

// MARK: - State protocol

/// There are two types of data that control a component: configuration and state.
/// configuration are simply the component proprieties, set by the parent and they are fixed
///  throughout the lifetime of a component.
/// For data that is going to change, we have to use state.
public protocol UIStateProtocol: class, ReflectedStringConvertible, Codable {
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
