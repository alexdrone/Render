import Foundation
import UIKit
import CoreRenderObjC

// MARK: - NodeBuilder

extension OpaqueNodeBuilder {
  public func onTouchUpInside(_ handler: @escaping (UIGestureRecognizer) -> Void) -> Self {
    withLayoutSpec { spec in spec.view?.onTouchUpInside(handler) }
  }
  
  public func onTouchDown(_ handler: @escaping (UIGestureRecognizer) -> Void) -> Self {
    withLayoutSpec { spec in spec.view?.onTouchDown(handler) }
  }

  public func onDoubleTap(_ handler: @escaping (UIGestureRecognizer) -> Void) -> Self {
    withLayoutSpec { spec in spec.view?.onDoubleTap(handler) }
  }

  public func onLongPress(_ handler: @escaping (UIGestureRecognizer) -> Void) -> Self {
    withLayoutSpec { spec in spec.view?.onLongPress(handler) }
  }

  public func onSwipeLeft(_ handler: @escaping (UIGestureRecognizer) -> Void) -> Self {
    withLayoutSpec { spec in spec.view?.onSwipeLeft(handler) }
  }

  public func onSwipeRight(_ handler: @escaping (UIGestureRecognizer) -> Void) -> Self {
    withLayoutSpec { spec in spec.view?.onSwipeRight(handler) }
  }

  public func onSwipeUp(_ handler: @escaping (UIGestureRecognizer) -> Void) -> Self {
    withLayoutSpec { spec in spec.view?.onSwipeUp(handler) }
  }

  public func onSwipeDown(_ handler: @escaping (UIGestureRecognizer) -> Void) -> Self {
    withLayoutSpec { spec in spec.view?.onSwipeDown(handler) }
  }

  public func onPan(_ handler: @escaping (UIGestureRecognizer) -> Void) -> Self {
    withLayoutSpec { spec in spec.view?.onPan(handler) }
  }

  public func onPinch(_ handler: @escaping (UIGestureRecognizer) -> Void) -> Self {
    withLayoutSpec { spec in spec.view?.onPinch(handler) }
  }

  public func onRotate(_ handler: @escaping (UIGestureRecognizer) -> Void) -> Self {
    withLayoutSpec { spec in spec.view?.onRotate(handler) }
  }

  public func onScreenEdgePan(_ handler: @escaping (UIGestureRecognizer) -> Void) -> Self {
    withLayoutSpec { spec in spec.view?.onScreenEdgePan(handler) }
  }
}

// MARK: - GestureRecognizer

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

extension UIView {
  func onGestureRecognizer<T: UIGestureRecognizer>(
    type: T.Type,
    key: NSString,
    numberOfTapsRequired: Int = 1,
    numberOfTouchesRequired: Int = 1,
    direction: UISwipeGestureRecognizer.Direction = UISwipeGestureRecognizer.Direction.down,
    _ handler: @escaping (UIGestureRecognizer) -> Void
  ) -> Void {
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

  public func onTouchUpInside(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(
      type: UITapGestureRecognizer.self,
      key: "\(#function)" as NSString,
      handler)
  }
  
  public func onTouchDown(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(
      type: TouchDownGestureRecognizer.self,
      key: "\(#function)" as NSString,
      handler)
  }

  public func onDoubleTap(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(
      type: UITapGestureRecognizer.self,
      key: "\(#function)" as NSString,
      numberOfTapsRequired: 2,
      handler)
  }

  public func onLongPress(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(
      type: UILongPressGestureRecognizer.self,
      key: "\(#function)" as NSString,
      handler)
  }

  public func onSwipeLeft(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(
      type: UISwipeGestureRecognizer.self,
      key: "\(#function)" as NSString,
      direction: UISwipeGestureRecognizer.Direction.left,
      handler)
  }

  public func onSwipeRight(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(
      type: UISwipeGestureRecognizer.self,
      key: "\(#function)" as NSString,
      direction: UISwipeGestureRecognizer.Direction.right,
      handler)
  }

  public func onSwipeUp(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(
      type: UISwipeGestureRecognizer.self,
      key: "\(#function)" as NSString,
      direction: UISwipeGestureRecognizer.Direction.up,
      handler)
  }

  public func onSwipeDown(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(
      type: UISwipeGestureRecognizer.self,
      key: "\(#function)" as NSString,
      direction: UISwipeGestureRecognizer.Direction.down,
      handler)
  }

  public func onPan(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(
      type: UIPanGestureRecognizer.self,
      key: "\(#function)" as NSString,
      handler)
  }

  public func onPinch(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(
      type: UIPinchGestureRecognizer.self,
      key: "\(#function)" as NSString,
      handler)
  }

  public func onRotate(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(
      type: UIRotationGestureRecognizer.self,
      key: "\(#function)" as NSString,
      handler)
  }

  public func onScreenEdgePan(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(
      type: UIScreenEdgePanGestureRecognizer.self,
      key: "\(#function)" as NSString,
      handler)
  }
}

// MARK: - Private

fileprivate class WeakGestureRecognizer: NSObject {
  weak var object: UIGestureRecognizer?
  var handler: ((UIGestureRecognizer) -> Void)? = nil

  @objc func handle(sender: UIGestureRecognizer) {
    handler?(sender)
  }
}

fileprivate var __handler: UInt8 = 0

class TouchDownGestureRecognizer: UIGestureRecognizer {
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    if self.state == .possible {
      self.state = .recognized
    }
  }
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    self.state = .failed
    }
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    self.state = .failed
  }
}
