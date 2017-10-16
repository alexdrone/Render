import UIKit

// MARK: - Props

public protocol UINodePropsProtocol {
  init()
}

public class UINilNodeProps: UINodePropsProtocol {
  public required init() { }
}

public func when<T>(_ expression: Bool?, _ yes: T, _ no: T, _ `default`: T) -> T {
  guard let expression = expression else {
    return `default`
  }
  return expression ? yes : no
}

public func unwrap(_ string: String?, _ `default`: String = "") -> String {
  return string ?? `default`
}
