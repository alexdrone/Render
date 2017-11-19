 import UIKit

// MARK: - UIViewPropertyProtocol

public protocol UIViewKeyPathProtocol {
  /// A unique identifier for the keyPath that is being assigned.
  var keyPathIdentifier: Int { get }
  /// Apply the computed property value to the view.
  func assign(view: UIView)
  /// Restore the property original value.
  func restore(view: UIView)
}

 public extension UINode {
  public final class UIViewKeyPathValue: UIViewKeyPathProtocol {
    /// A unique identifier for the keyPath being assigned.
    public let keyPathIdentifier: Int
    /// The [property] application closure.
    private var applyClosure: ((V) -> Void)? = nil
    /// The [property] removal closure.
    private var removeClosure: ((V) -> Void)? = nil
    /// An optional animator for the property.
    private var animator: UIViewPropertyAnimator?

    init<T>(keyPath: ReferenceWritableKeyPath<V, T>,
            value: @escaping () -> T,
            animator: UIViewPropertyAnimator? = nil) {
      self.keyPathIdentifier = keyPath.identifier
      self.animator = animator

      self.applyClosure = { [weak self] (view: V) in
        let value = value()
        if NSObjectProtocolEqual(lhs: value, rhs: view[keyPath: keyPath]) { return }
        self?.apply(view: view, keyPath: keyPath, value: value)
      }
      self.removeClosure = { [weak self] (view: V) in
        self?.remove(view: view, keyPath: keyPath)
      }
    }

    public convenience init<T>(keyPath: ReferenceWritableKeyPath<V, T>,
                               value: T,
                               animator: UIViewPropertyAnimator? = nil) {
      self.init(keyPath: keyPath, value: { value }, animator: animator)
    }

    private func apply<T>(view: V, keyPath: ReferenceWritableKeyPath<V, T>, value: T) {
      // Caches the initial value.
      view.renderContext.initialConfiguration.storeInitialValue(keyPath: keyPath)
      if let animator = animator {
        animator.addAnimations {
          view[keyPath: keyPath] = value
        }
        animator.startAnimation()
      } else {
        view[keyPath: keyPath] = value
      }
    }

    private func remove<T>(view: V, keyPath: ReferenceWritableKeyPath<V, T>) {
      guard let value = view.renderContext.initialConfiguration.initialValue(keyPath: keyPath) else{
        return
      }
      view[keyPath: keyPath] = value
    }

    /// Apply the computed property value to the view.
    public func assign(view: UIView) {
      guard let view = view as? V else {
        print("Unable to assign the property \(keyPathIdentifier): invalid state supplied.")
        return
      }
      applyClosure?(view)
    }

    /// Restore the property original value.
    public func restore(view: UIView) {
      guard let view = view as? V else { return }
      removeClosure?(view)
    }
  }
}

extension AnyKeyPath {
  /// Returns a unique identifier for the keyPath.
  public var identifier: Int { return hashValue }
}

@objc public final class UIRenderConfigurationContainer: NSObject {
  /// The node that originated this view.
  public weak var node: UINodeProtocol?
  public weak var view: UIView?
  /// The current mutated properties.
  let appliedConfiguration: [Int: UIViewKeyPathProtocol] = [:]
  /// The initial value for the propeties that are currenly assigned.
  public let initialConfiguration: UIViewPropertyInitalContainer
  /// Whether the view has been created at the last render pass.
  public var isNewlyCreated: Bool = false;
  /// The frame from the previous layout pass.
  public var oldFrame: CGRect = CGRect.zero
  /// The frame after the current layout pass.
  public var newFrame: CGRect = CGRect.zero
  /// The original alpha of the view.
  public var targetAlpha: CGFloat = 1

  init(view: UIView) {
    initialConfiguration = UIViewPropertyInitalContainer(view: view)
    self.view = view
  }

  func storeOldGeometryRecursively() {
    guard let view = view, view.hasNode else {
      return
    }
    oldFrame = view.frame
    for subview in view.subviews {
      subview.renderContext.storeOldGeometryRecursively()
    }
  }

  func applyOldGeometryRecursively() {
    guard let view = view, view.hasNode else {
      return
    }
    guard !(isNewlyCreated && oldFrame == CGRect.zero) else {
      view.alpha = 0
      return
    }
    view.frame = oldFrame
    for subview in view.subviews {
      subview.renderContext.applyOldGeometryRecursively()
    }
  }

  func storeNewGeometryRecursively() {
    guard let view = view, view.hasNode else {
      return
    }
    newFrame = view.frame
    targetAlpha = view.alpha
    for subview in view.subviews {
      subview.renderContext.storeNewGeometryRecursively()
    }
  }

  func applyNewGeometryRecursively() {
    guard let view = view, view.hasNode else {
      return
    }
    view.frame = newFrame

    for subview in view.subviews {
      subview.renderContext.applyNewGeometryRecursively()
    }
  }

  private func applyTransformationsToNewlyCreatedViews() {
    guard let view = view, view.hasNode else {
      return
    }
    if fabs(view.alpha - targetAlpha) > CGFloat.epsilon {
      view.alpha = targetAlpha
    }
    for subview in view.subviews {
      subview.renderContext.applyTransformationsToNewlyCreatedViews()
    }
  }

  func fadeInNewlyCreatedViews(delay: TimeInterval = 0) {
    guard let view = view, view.hasNode else {
      return
    }
    UIView.animate(withDuration: 0.16, delay: delay, options: .curveEaseInOut, animations: {
      view.renderContext.applyTransformationsToNewlyCreatedViews()
    }, completion: nil)
  }
}

// MARK: - UIViewPropertyInitalContainer

@objc public final class UIViewPropertyInitalContainer: NSObject {
  weak var view: UIView?
  @nonobjc var initialValues: [Int: Any] = [:]

  /// Initialize the container with its associated view.
  init(view: UIView) {
    self.view = view
    super.init()
  }

  /// Returns (and caches) the initial value for the view.
  @nonobjc func initialValue<V: UIView, P>(keyPath: ReferenceWritableKeyPath<V, P>) -> P? {
    guard let view: V = castView() else {
      return nil
    }
    guard let value = initialValues[keyPath.identifier] as? P else {
      let value = view[keyPath: keyPath]
      initialValues[keyPath.identifier] = value
      return value
    }
    return value
  }

  /// Initialize the initial value for the property (if necessary).
  @nonobjc func storeInitialValue<V: UIView, P>(keyPath: ReferenceWritableKeyPath<V, P>) {
    _ = initialValue(keyPath: keyPath)
  }

  /// Casts the view to its expected type.
  @nonobjc private func castView<V>() -> V? {
    guard let view = self.view as? V else {
      print("The view is not of the expected type \(V.self)).")
      return nil
    }
    return view
  }
}

@inline(__always) func NSObjectProtocolEqual(lhs: Any?, rhs: Any?) -> Bool {
  if let olhs = lhs as? NSObjectProtocol, let orhs = rhs as? NSObjectProtocol, olhs.isEqual(orhs){
    return true
  } else {
    return false
  }
}

