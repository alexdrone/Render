 import UIKit

// MARK: - UIViewPropertyProtocol

public protocol UIViewKeyPathProtocol {
  /// A unique identifier for the keyPath being assigned.
  var keyPathIdentifier: Int { get }
  /// Apply the computed property value to the view.
  func assign(view: UIView)
  /// Restore the property original value.
  func restore(view: UIView)
}

public extension _UINode {

  typealias `$` = UIViewKeyPathValue

  public final class UIViewKeyPathValue: UIViewKeyPathProtocol {
    /// A unique identifier for the keyPath being assigned.
    public let keyPathIdentifier: Int
    /// The application closure.
    private var applyClosure: ((V) -> Void)? = nil
    /// The removal closure.
    private var removeClosure: ((V) -> Void)? = nil
    /// An optional animator for the property.
    private var animator: UIViewPropertyAnimator?

    init<T>(keyPath: ReferenceWritableKeyPath<V, T>,
            value: @escaping () -> T,
            animator: UIViewPropertyAnimator? = nil) {
      self.keyPathIdentifier = keyPath.identifier
      self.animator = animator

      self.applyClosure = { [weak self] (view: V) in
        self?.apply(view: view, keyPath: keyPath, value: value())
      }
      self.removeClosure = { [weak self] (view: V) in
        self?.remove(view: view, keyPath: keyPath)
      }
    }

    init<T: Equatable>(keyPath: ReferenceWritableKeyPath<V, T>,
                       value: @escaping () -> T,
                       animator: UIViewPropertyAnimator? = nil) {
      self.keyPathIdentifier = keyPath.identifier
      self.animator = animator

      self.applyClosure = { [weak self] (view: V) in
        let oldValue = view[keyPath: keyPath]
        let newValue = value()
        if oldValue != newValue {
          self?.apply(view: view, keyPath: keyPath, value: newValue)
        }
      }
      self.removeClosure = { [weak self] (view: V) in
        let oldValue = view[keyPath: keyPath]
        let newValue = view.configuration.initialConfiguration.initialValue(keyPath: keyPath)
        if oldValue != newValue {
          self?.remove(view: view, keyPath: keyPath)
        }
      }
    }

    public convenience init<T>(keyPath: ReferenceWritableKeyPath<V, T>,
                               value: T,
                               animator: UIViewPropertyAnimator? = nil) {
      self.init(keyPath: keyPath, value: { value }, animator: animator)
    }

    public convenience init<T: Equatable>(keyPath: ReferenceWritableKeyPath<V, T>,
                                          value: T,
                                          animator: UIViewPropertyAnimator? = nil) {
      self.init(keyPath: keyPath, value: { value }, animator: animator)
    }

    private func apply<T>(view: V, keyPath: ReferenceWritableKeyPath<V, T>, value: T) {
      // Caches the initial value.
      view.configuration.initialConfiguration.storeInitialValue(keyPath: keyPath)
      // TODO: add animator support.
      view[keyPath: keyPath] = value
    }

    private func remove<T>(view: V, keyPath: ReferenceWritableKeyPath<V, T>) {
      guard let value = view.configuration.initialConfiguration.initialValue(keyPath: keyPath) else{
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
      guard let view = view as? V else {
        return
      }
      removeClosure?(view)
    }
  }
}

extension AnyKeyPath {
  
  /// Returns a unique identifier for the keyPath.
  public var identifier: Int { return hashValue }
}


@objc public final class UIRenderConfigurationContainer: NSObject {
  /// The node that originated this.
  public weak var node: UINodeProtocol?
  /// The initial value of the configuration that are going to be assigned.
  public let appliedConfiguration: [Int: UIViewKeyPathProtocol] = [:]
  /// The initial value of the configuration that are going to be assigned.
  public let initialConfiguration: UIViewPropertyInitalContainer
  /// Whether the view has been created at the last render pass.
  public var isNewlyCreated: Bool = false;
  /// The original value of the alpha at creation time.
  public var alphaBeforeTransition: CGFloat = 1
  /// Returns the state for the node associated to this view.
  public func state<S: UIStateProtocol>() -> S? {
    return node?._state as? S
  }

  init(view: UIView) {
    initialConfiguration = UIViewPropertyInitalContainer(view: view)
  }
}

// MARK: - configuration initial values

@objc public final class UIViewPropertyInitalContainer: NSObject {
  /// The associated view.
  weak var view: UIView?
  /// Stores the initial values for a view.
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


