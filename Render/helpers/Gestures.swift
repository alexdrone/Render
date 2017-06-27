import UIKit

public extension UIControl {
  public func on(event: UIControlEvents, _ closure: @escaping ()->()) {
    let sleeve = ClosureSleeve(for: self, closure)
    addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: event)
  }
}

public extension UIView {

  public func onTap(_ handler: @escaping (UITapGestureRecognizer) -> Void) {
    addGestureRecognizer(UITapGestureRecognizer(taps: 1, handler: handler))
  }

  public func onDoubleTap(_ handler: @escaping (UITapGestureRecognizer) -> Void) {
    addGestureRecognizer(UITapGestureRecognizer(taps: 2, handler: handler))
  }

  public func onLongPress(_ handler: @escaping (UILongPressGestureRecognizer) -> Void) {
    addGestureRecognizer(UILongPressGestureRecognizer(handler: handler))
  }

  public func onSwipeLeft(_ handler: @escaping (UISwipeGestureRecognizer) -> Void) {
    addGestureRecognizer(UISwipeGestureRecognizer(direction: .left, handler: handler))
  }

  public func onSwipeRight(_ handler: @escaping (UISwipeGestureRecognizer) -> Void) {
    addGestureRecognizer(UISwipeGestureRecognizer(direction: .right, handler: handler))
  }

  public func onSwipeUp(_ handler: @escaping (UISwipeGestureRecognizer) -> Void) {
    addGestureRecognizer(UISwipeGestureRecognizer(direction: .up, handler: handler))
  }

  public func onSwipeDown(_ handler: @escaping (UISwipeGestureRecognizer) -> Void) {
    addGestureRecognizer(UISwipeGestureRecognizer(direction: .down, handler: handler))
  }

  public func onPan(_ handler: @escaping (UIPanGestureRecognizer) -> Void) {
    addGestureRecognizer(UIPanGestureRecognizer(handler: handler))
  }

  public func onPinch(_ handler: @escaping (UIPinchGestureRecognizer) -> Void) {
    addGestureRecognizer(UIPinchGestureRecognizer(handler: handler))
  }

  public func onRotate(_ handler: @escaping (UIRotationGestureRecognizer) -> Void) {
    addGestureRecognizer(UIRotationGestureRecognizer(handler: handler))
  }

  public func onScreenEdgePan(_ handler: @escaping (UIScreenEdgePanGestureRecognizer) -> Void) {
    addGestureRecognizer(UIScreenEdgePanGestureRecognizer(handler: handler))
  }
}

// MARK: - Private

private class ClosureSleeve {
  let closure: () -> Void
  init(for object: AnyObject, _ closure: @escaping () -> Void) {
    self.closure = closure
    objc_setAssociatedObject(object,
                             String(format: "[%d]", arc4random()),
                             self,
                             objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN
    )
  }
  @objc func invoke () {
    closure()
  }
}

private let ClosureHandlerSelector = Selector(("handle"))
private class ClosureHandler<T: AnyObject>: NSObject {
  var handler: ((T) -> Void)?
  weak var control: T?

  init(handler: @escaping (T) -> Void, control: T? = nil) {
    self.handler = handler
    self.control = control
  }

  func handle() {
    if let control = self.control {
      handler?(control)
    }
  }
}

fileprivate var HandlerKey: UInt8 = 0
fileprivate extension UIGestureRecognizer {

  fileprivate func setHandler<T: UIGestureRecognizer>(_ instance: T, handler: ClosureHandler<T>) {
    objc_setAssociatedObject(self, &HandlerKey, handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    handler.control = instance
  }

  fileprivate func handler<T>() -> ClosureHandler<T> {
    return objc_getAssociatedObject(self, &HandlerKey) as! ClosureHandler
  }
}

extension UITapGestureRecognizer {
  public convenience init(taps: Int = 1,
                          touches: Int = 1,
                          handler: @escaping (UITapGestureRecognizer) -> Void) {
    let handler = ClosureHandler<UITapGestureRecognizer>(handler: handler)
    self.init(target: handler, action: ClosureHandlerSelector)
    setHandler(self, handler: handler)
    numberOfTapsRequired = taps
    numberOfTouchesRequired = touches
  }
}

extension UILongPressGestureRecognizer {
  public convenience init(handler: @escaping (UILongPressGestureRecognizer) -> Void) {
    let handler = ClosureHandler<UILongPressGestureRecognizer>(handler: handler)
    self.init(target: handler, action: ClosureHandlerSelector)
    setHandler(self, handler: handler)
  }
}

extension UISwipeGestureRecognizer {
  public convenience init(direction: UISwipeGestureRecognizerDirection,
                          handler: @escaping (UISwipeGestureRecognizer) -> Void) {
    let handler = ClosureHandler<UISwipeGestureRecognizer>(handler: handler)
    self.init(target: handler, action: ClosureHandlerSelector)
    setHandler(self, handler: handler)
    self.direction = direction
  }
}

extension UIPanGestureRecognizer {
  public convenience init(handler: @escaping (UIPanGestureRecognizer) -> Void) {
    let handler = ClosureHandler<UIPanGestureRecognizer>(handler: handler)
    self.init(target: handler, action: ClosureHandlerSelector)
    setHandler(self, handler: handler)
  }
}

extension UIPinchGestureRecognizer {
  public convenience init(handler: @escaping (UIPinchGestureRecognizer) -> Void) {
    let handler = ClosureHandler<UIPinchGestureRecognizer>(handler: handler)
    self.init(target: handler, action: ClosureHandlerSelector)
    setHandler(self, handler: handler)
  }
}

extension UIRotationGestureRecognizer {
  public convenience init(handler: @escaping (UIRotationGestureRecognizer) -> Void) {
    let handler = ClosureHandler<UIRotationGestureRecognizer>(handler: handler)
    self.init(target: handler, action: ClosureHandlerSelector)
    setHandler(self, handler: handler)
  }
}

extension UIScreenEdgePanGestureRecognizer {
  public convenience init(handler: @escaping (UIScreenEdgePanGestureRecognizer) -> Void) {
    let handler = ClosureHandler<UIScreenEdgePanGestureRecognizer>(handler: handler)
    self.init(target: handler, action: ClosureHandlerSelector)
    setHandler(self, handler: handler)
  }
}



