import UIKit

// MARK: - Props

public protocol UINodePropsProtocol {
  init()
}

public class UINilNodeProps: UINodePropsProtocol {
  public required init() { }
}
