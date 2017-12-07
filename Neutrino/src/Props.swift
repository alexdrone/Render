import UIKit

// MARK: - UIProp

/// Prop (short for properties) are a Component's configuration. They are received from above and
/// immutable as far as the Component receiving them is concerned.
/// A Component cannot change its props, but it is responsible for putting together the props of
/// its child Component.
/// Prop do not have to just be data -- callback functions may be passed in as props.
public protocol UIPropsProtocol: ReflectedStringConvertible {
  init()
}

open class UIProps: UIPropsProtocol {
  public required init() { }
}

public class UINilProps: UIPropsProtocol, Codable {
  public static let `nil` = UINilProps()
  public required init() { }
}
