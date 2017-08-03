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
fileprivate var hadleOldCornerRadius: UInt8 = 0
fileprivate var handleOldAlpha: UInt8 = 0

public extension UIView {

  public var isAnimatable: Bool {
    get { return getBool(&handleAnimatable, self, defaultIfNil: true) }
    set { setBool(&handleAnimatable, self, newValue) }
  }

  public var hasNode: Bool {
    get { return getBool(&handleHasNode, self, defaultIfNil: false) }
    set { setBool(&handleHasNode, self, newValue) }
  }

  public var isNewlyCreated: Bool {
    get { return getBool(&handleNewlyCreated, self, defaultIfNil: false) }
    set { setBool(&handleNewlyCreated, self, newValue) }
  }

  public var cornerRadius: CGFloat {
    get { return layer.cornerRadius }
    set {
      oldCornerRadius = layer.cornerRadius
      clipsToBounds = true
      layer.cornerRadius = newValue
    }
  }

  public var oldCornerRadius: CGFloat {
    get { return getFloat(&hadleOldCornerRadius, self) }
    set { setFloat(&hadleOldCornerRadius, self, newValue) }
  }

  public var oldAlpha: CGFloat {
    get { return getFloat(&handleOldAlpha, self) }
    set { setFloat(&handleOldAlpha, self, newValue) }
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

  public func animateCornerRadiusInHierarchyIfNecessary(duration: CFTimeInterval) {
    animateCornerRadius(duration: duration)
    for subview in subviews where subview.hasNode {
      subview.animateCornerRadiusInHierarchyIfNecessary(duration: duration)
    }
  }

  public func debugBoudingRect() {
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


//MARK: - Gesture recognizers

class WeakGestureRecognizer: NSObject {
  weak var object: UIGestureRecognizer?
  var handler: ((UIGestureRecognizer) -> Void)? = nil

  @objc func handle(sender: UIGestureRecognizer) {
    handler?(sender)
  }
}

fileprivate var __handler: UInt8 = 0
extension UIView {

  /// All of the gesture recognizers registered through the closure based api.
  var gestureRecognizerProxyDictionary: NSMutableDictionary {
    get {
      if let obj = objc_getAssociatedObject(self, &__handler) as? NSMutableDictionary {
        return obj
      }
      let obj = NSMutableDictionary()
      objc_setAssociatedObject(self, &__handler, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return obj
    }
    set {
      objc_setAssociatedObject(self, &__handler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  /// Flush all of the existing gesture recognizers registered through the closure based api.
  public func flushGestureRecognizers() {
    guard let array = gestureRecognizerProxyDictionary.allValues as? [WeakGestureRecognizer] else {
      return
    }
    for obj in array {
      obj.handler = nil
      if let gesture = obj.object {
        gesture.removeTarget(nil, action: nil)
        gesture.view?.removeGestureRecognizer(gesture)
      }
      obj.object = nil
    }
    gestureRecognizerProxyDictionary = NSMutableDictionary()
  }

  /// Flush all of the existing gesture recognizers registered through the closure based api.
  public func flushGestureRecognizersRecursively() {
    flushGestureRecognizers()
    for subview in subviews {
      subview.flushGestureRecognizersRecursively()
    }
  }
}

public extension UIView {

  public func onGestureRecognizer<T: UIGestureRecognizer>(
    type: T.Type,
    key: NSString,
    numberOfTapsRequired: Int = 1,
    numberOfTouchesRequired: Int = 1,
    direction: UISwipeGestureRecognizerDirection = .down,
    _ handler: @escaping (UIGestureRecognizer) -> Void) {

    let wrapper = WeakGestureRecognizer()
    wrapper.handler = handler
    let selector = #selector(WeakGestureRecognizer.handle(sender:))
    let gesture = T(target: wrapper, action: selector)
    wrapper.object = gesture
    if let tapGesture = gesture as? UITapGestureRecognizer {
      tapGesture.numberOfTapsRequired = numberOfTapsRequired
      tapGesture.numberOfTouchesRequired = numberOfTouchesRequired
    }
    if let swipeGesture = gesture as? UISwipeGestureRecognizer {
      swipeGesture.direction = direction
    }
    // Safely remove the old gesture recognizer.
    if let old = gestureRecognizerProxyDictionary.object(forKey: key) as? WeakGestureRecognizer,
      let oldGesture = old.object {
      old.handler = nil
      old.object = nil
      oldGesture.removeTarget(nil, action: nil)
      oldGesture.view?.removeGestureRecognizer(oldGesture)
    }
    gestureRecognizerProxyDictionary.setObject(wrapper, forKey: key)
    addGestureRecognizer(gesture)
  }

  public func onTap(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UITapGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        handler)
  }

  public func onDoubleTap(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UITapGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        numberOfTapsRequired: 2,
                        handler)
  }

  public func onLongPress(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UILongPressGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        handler)
  }

  public func onSwipeLeft(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UISwipeGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        direction: .left,
                        handler)
  }

  public func onSwipeRight(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UISwipeGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        direction: .right,
                        handler)
  }

  public func onSwipeUp(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UISwipeGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        direction: .up,
                        handler)
  }

  public func onSwipeDown(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UISwipeGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        direction: .down,
                        handler)
  }

  public func onPan(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UIPanGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        handler)
  }

  public func onPinch(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UIPinchGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        handler)
  }

  public func onRotate(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UIRotationGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        handler)
  }

  public func onScreenEdgePan(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UIScreenEdgePanGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        handler)
  }
}
