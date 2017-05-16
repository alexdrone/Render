import Foundation
import UIKit

public extension CGFloat {
  public static let undefined: CGFloat = YGNaNSize.width
  public static let max: CGFloat = CGFloat(Float.greatestFiniteMagnitude)
  public static let epsilon: CGFloat = CGFloat(Float.ulpOfOne)
}

public extension CGSize {
  public static let undefined: CGSize = CGSize(width: CGFloat.undefined, height: CGFloat.undefined)
  public static let max: CGSize =  CGSize(width: CGFloat.max, height: CGFloat.max)
  public static let epsilon: CGSize =  CGSize(width: CGFloat.epsilon, height: CGFloat.epsilon)
}

public extension CGRect {
  public mutating func normalize() {
    self.origin.x = self.origin.x.isNormal ? self.origin.x : 0
    self.origin.y = self.origin.y.isNormal ? self.origin.y : 0
    self.size.width = self.size.width.isNormal ? self.size.width : 0
    self.size.height = self.size.height.isNormal ? self.size.height : 0
  }
}

fileprivate var handleAnimatable: UInt8 = 0
fileprivate var handleHasNode: UInt8 = 0
fileprivate var handleNewlyCreated: UInt8 = 0

public extension UIView {

  public var isAnimatable: Bool {
    get { return getBool(&handleAnimatable, self, defaultIfNil: true) }
    set { setBool(&handleAnimatable, self, newValue) }
  }

  internal var hasNode: Bool {
    get { return getBool(&handleHasNode, self, defaultIfNil: false) }
    set { setBool(&handleHasNode, self, newValue) }
  }

  internal var isNewlyCreated: Bool {
    get { return getBool(&handleNewlyCreated, self, defaultIfNil: false) }
    set { setBool(&handleNewlyCreated, self, newValue) }
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

