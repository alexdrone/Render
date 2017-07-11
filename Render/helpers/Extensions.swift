import Foundation
import UIKit

public extension CGFloat {
  public static let undefined: CGFloat = YGNaNSize.width
  public static let max: CGFloat = 32768
  public static let epsilon: CGFloat = CGFloat(Float.ulpOfOne)
  public var maxIfZero: CGFloat { return self == 0 ? CGFloat.max : self }
  public var undefinedIfZero: CGFloat { return self == 0 ? CGFloat.undefined : self }
  public var normal: CGFloat { return isNormal ? self : 0  }
}

public extension CGSize {
  public static let undefined: CGSize = CGSize(width: CGFloat.undefined, height: CGFloat.undefined)
  public static let max: CGSize =  CGSize(width: CGFloat.max, height: CGFloat.max)
  public static let epsilon: CGSize =  CGSize(width: CGFloat.epsilon, height: CGFloat.epsilon)
  public static func ===(lhs: CGSize, rhs: CGSize) -> Bool {
    return fabs(lhs.width - rhs.width) < CGFloat.epsilon &&
           fabs(lhs.height - rhs.height) < CGFloat.epsilon
  }
}

public extension CGRect {
  public mutating func normalize() {
    origin.x = origin.x.isNormal ? origin.x : 0
    origin.y = origin.y.isNormal ? origin.y : 0
    size.width = size.width.isNormal ? size.width : 0
    size.height = size.height.isNormal ? size.height : 0
  }
}

fileprivate var handleAnimatable: UInt8 = 0
fileprivate var handleHasNode: UInt8 = 0
fileprivate var handleNewlyCreated: UInt8 = 0
fileprivate var oldCornerRadiusHandle: UInt8 = 0

public extension UIView {

  public var isAnimatable: Bool {
    get { return getBool(&handleAnimatable, self, defaultIfNil: true) }
    set { setBool(&handleAnimatable, self, newValue) }
  }

  var hasNode: Bool {
    get { return getBool(&handleHasNode, self, defaultIfNil: false) }
    set { setBool(&handleHasNode, self, newValue) }
  }

  var isNewlyCreated: Bool {
    get { return getBool(&handleNewlyCreated, self, defaultIfNil: false) }
    set { setBool(&handleNewlyCreated, self, newValue) }
  }

  var cornerRadius: CGFloat {
    get { return layer.cornerRadius }
    set {
      oldCornerRadius = layer.cornerRadius
      clipsToBounds = true
      layer.cornerRadius = newValue
    }
  }

  var oldCornerRadius: CGFloat {
    get { return getFloat(&handleNewlyCreated, self) }
    set { setFloat(&handleNewlyCreated, self, newValue) }
  }

  private func animateCornerRadius(duration: CFTimeInterval) {
    if fabs(oldCornerRadius - oldCornerRadius) < CGFloat.epsilon {
      return
    }
    let key = "cornerRadius"
    let animation = CABasicAnimation(keyPath: key)
    animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
    animation.fromValue = oldCornerRadius
    animation.toValue = layer.cornerRadius
    animation.duration = duration
    self.layer.add(animation, forKey: key)
    self.layer.cornerRadius = layer.cornerRadius
  }

  func animateCornerRadiusInHierarchyIfNecessary(duration: CFTimeInterval) {
    animateCornerRadius(duration: duration)
    for subview in subviews where subview.hasNode {
      subview.animateCornerRadiusInHierarchyIfNecessary(duration: duration)
    }
  }

  func debugBoudingRect() {
    layer.borderColor = UIColor.red.cgColor
    layer.borderWidth = 2
  }
}

fileprivate func getBool(_ handle: UnsafeRawPointer!, _ object: UIView, defaultIfNil: Bool) -> Bool {
  return (objc_getAssociatedObject(object, handle) as? NSNumber)?.boolValue ?? defaultIfNil
}
fileprivate func getBool(_ handle: UnsafeRawPointer!, _ object: UIView, _ value: Bool) -> Bool {
  return (objc_getAssociatedObject(object, handle) as? NSNumber)?.boolValue ?? value
}

fileprivate func setBool(_ handle: UnsafeRawPointer!, _ object: UIView, _ value: Bool) {
  objc_setAssociatedObject(object,
                           handle,
                           NSNumber(value: value),
                           .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}

fileprivate func getFloat(_ handle: UnsafeRawPointer!,
                          _ object: UIView) -> CGFloat {
  return CGFloat((objc_getAssociatedObject(object, handle) as? NSNumber)?.floatValue ?? 0)
}

fileprivate func setFloat(_ handle: UnsafeRawPointer!, _ object: UIView, _ value: CGFloat) {
  objc_setAssociatedObject(object,
                           handle,
                           NSNumber(value: Float(value)),
                           .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}




