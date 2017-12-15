import UIKit

// MARK: UIView

public extension UIView {
  /// *Internal only* some of render transient configuration for this view.
  var renderContext: UIRenderConfigurationContainer {
    get {
      typealias C = UIRenderConfigurationContainer
      guard let obj = objc_getAssociatedObject(self, &_handleContext) as? C else {
          let container = C(view: self)
          objc_setAssociatedObject(self, &_handleContext, container, nonatomic)
          return container
      }
      return obj
    }
    set {
      objc_setAssociatedObject(self, &_handleContext, newValue, nonatomic)
    }
  }
  /// Whether this view has a node currently associated to it or not.
  public var hasNode: Bool {
    get {
      return (objc_getAssociatedObject(self, &_handleHasNode) as? NSNumber)?.boolValue ?? false
    }
    set {
      objc_setAssociatedObject(self, &_handleHasNode, NSNumber(value: newValue), nonatomic)
    }
  }

  /// Remove all of the registered targets if this view is a subclass of *UIControl*.
  func resetAllTargets() {
    if let control = self as? UIControl {
      for target in control.allTargets {
        control.removeTarget(target, action: nil, for: .allEvents)
      }
    }
  }

}

// MARK: Geometry

public extension CGFloat {
  /// Used for flexible dimensions (*Yoga specific value*).
  public static let undefined: CGFloat = YGNaNSize.width
  /// An arbitrary large number to use for non-constrained layout.
  public static let max: CGFloat = 32768
  /// The positive difference between 1.0 and the next greater representable number.
  public static let epsilon: CGFloat = CGFloat(Float.ulpOfOne)
  /// Returns *0* if the number is NaN of inf.
  public var normal: CGFloat { return isNormal ? self : 0  }
}

public extension CGSize {
  /// Used for flexible dimensions (*Yoga specific value*).
  public static let undefined: CGSize = CGSize(width: CGFloat.undefined, height: CGFloat.undefined)
  /// An arbitrary large number to use for non-constrained layout.
  public static let max: CGSize =  CGSize(width: CGFloat.max, height: CGFloat.max)
  /// The positive difference between 1.0 and the next greater representable number.
  public static let epsilon: CGSize =  CGSize(width: CGFloat.epsilon, height: CGFloat.epsilon)
  /// CGSize equatable implementation.
  public static func ===(lhs: CGSize, rhs: CGSize) -> Bool {
    return  fabs(lhs.width - rhs.width) < CGFloat.epsilon
            && fabs(lhs.height - rhs.height) < CGFloat.epsilon
  }
}

public extension CGRect {
  /// Returns *0* if the number is NaN of inf.
  public mutating func normalize() {
    origin.x = origin.x.isNormal ? origin.x : 0
    origin.y = origin.y.isNormal ? origin.y : 0
    size.width = size.width.isNormal ? size.width : 0
    size.height = size.height.isNormal ? size.height : 0
  }
}

//MARK: - Private

private var _handleHasNode: UInt8 = 0
private var _handleContext: UInt8 = 0
private let nonatomic = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
