import UIKit

public protocol UIContextProtocol: Disposable {
  /// Retrieves the state for the key passed as argument.
  /// If no state is registered yet, a new one will be allocated and returned.
  /// - parameter type: The desired *UIState* subclass.
  /// - parameter key: The unique key associated with this state.
  func state<S: UIStateProtocol>(_ type: S.Type, key: String) -> S
  /// Retrieves the component for the key passed as argument.
  /// If no component is registered yet, a new one will be allocated and returned.
  /// - parameter type: The desired *UIComponent* subclass.
  /// - parameter key: The unique key associated with this component.
  /// - parameter props: Configurations and callbacks passed down to the component.
  /// - parameter parent: Optional if the component is not the root node.
  func component<S, P, C: UIComponent<S, P>>(_ type: C.Type,
                                             key: String,
                                             props: P,
                                             parent: UIComponentProtocol?) -> C
  /// Creates a new volatile stateless component.
  /// - parameter type: The desired *UIComponent* subclass.
  /// - parameter props: Configurations and callbacks passed down to the component.
  /// - parameter parent: Optional if the component is not the root node.
  func transientComponent<S, P, C: UIComponent<S, P>>(_ type: C.Type,
                                                      props: P,
                                                      parent: UIComponentProtocol?) -> C
  /// Prevents any calls to 'setNeedRender' to trigger the component relayout.
  /// Useful when a manual manipulation of the view hierarchy is ongoing (e.g. interactable
  /// animation).
  func suspendComponentRendering()
  /// Restore the normal 'setNeedRender' behaviour.
  func resumeComponentRendering()
  /// Register a new delegate for this context.
  /// - note: Many delegates can be registered at the same time and the context hold only weak
  /// references to them.
  func registerDelegate(_ delegate: UIContextDelegate)
  /// Remove a delegate for this context.
  func unregister(_ delegate: UIContextDelegate)
  /// A root component registered this context just got rendered.
  /// - note: This is automatically called from *UIComponent* subclasses.
  func didRenderRootComponent(_ component: UIComponentProtocol)
  /// *Optional* the property animator that is going to be used for frame changes in the component
  /// subtree.
  /// - note: This field is auotmatically reset to 'nil' at the end of every 'render' pass.
  var layoutAnimator: UIViewPropertyAnimator? { get set }
  /// State and component object pool that guarantees uniqueness of 'UIState' and 'UIComponent'
  /// instances within the same context.
  var pool: UIContextPool { get }
  /// Interface idiom, orientation and bounds for the screen and the canvas view associted to this
  /// context.
  var screen: UIScreenStateFactory.State { get }
  /// Gets rid of the obsolete states.
  /// - parameter validKeys: The keys for the components currently rendered on screen.
  func flushObsoleteState(validKeys: Set<String>)
  // Prevent *beginUpdates()* and *endUpdates()* to be called on the table view on this instance
  // of render.
  var _preventTableUpdates: Bool { get set }
  // *Internal only* component construction sanity check.
  var _componentInitFromContext: Bool { get}
  // *Internal only* true is suspendComponentRendering has been called on this context.
  var _isRenderSuspended: Bool { get }
  /// *Internal only* Associate a parent context.
  var _parentContext: UIContextProtocol? { get set }
  // *Internal only* The canvas view in which the component will be rendered in.
  var _canvasView: UIView? { get set }
  // *Internal only*.
  var _screenStateFactory: UIScreenStateFactory { get }
  // *Internal only*.
  // This is not 'nil' if the context has been intiialized from a *UITableComponentViewController*.
  var _associatedTableViewController: UITableComponentViewController? { get set }
}

public protocol UIContextDelegate: class {
  /// Called whenever *setNeedRender* is called on any of the compoenets belonging to this context.
  func setNeedRenderInvoked(on context: UIContextProtocol, component: UIComponentProtocol)
}

// MARK: - UIContext

public class UIContext: UIContextProtocol {
  public var pool = UIContextPool()
  /// Returns the bounds of the canvas view.
  public var canvasSize: CGSize {
    return _canvasView?.bounds.size ?? UIScreen.main.nativeBounds.size
  }
  // The property animator that is going to be used for frame changes in the subtree.
  public var layoutAnimator: UIViewPropertyAnimator?
  // All the delegates registered for this object.
  private var delegates: [UIContextDelegateWeakRef] = []
  // The canvas view in which the component will be rendered in.
  public weak var _canvasView: UIView?
  // In charge of returing the current state of the screen.
  public lazy var _screenStateFactory: UIScreenStateFactory = {
    return UIScreenStateFactory(canvasViewProvider: { [weak self] in return self?._canvasView })
  }()
  public var _preventTableUpdates: Bool = false
  // Sanity check for context initialization.
  public var _componentInitFromContext: Bool = false
  // Associated a parent context.
  public weak var _parentContext: UIContextProtocol?
  // suspendComponentRendering has been called on this context.
  public private(set) var _isRenderSuspended: Bool = false
  /// Interface idiom, orientation and bounds for the screen and the canvas view associted to this
  /// context.
  public var screen: UIScreenStateFactory.State {
    return _screenStateFactory.state()
  }
  /// Whether this object has been disposed or not.
  /// Once an object is disposed it cannot be used any longer.
  public var isDisposed: Bool = false
  /// This is not 'nil' if the context has been intiialized from a *UITableComponentViewController*.
  public weak var _associatedTableViewController: UITableComponentViewController?

  public init() {
    logAlloc(type: "UIContext", object: self, details: allocationInfo)
  }

  deinit {
    dispose()
    logDealloc(type: "UIContext", object: self)
  }

  private var allocationInfo: String? {
    if self is UIStylesheetContext {
      return "(Stylesheet)"
    } else if self is UICellContext {
      return "(Cells)"
    }
    return nil
  }

  public func state<S: UIStateProtocol>(_ type: S.Type, key: String) -> S {
    return pool.state(key: key)
  }

  public func component<S, P, C: UIComponent<S, P>>(_ type: C.Type,
                                                    key: String = string(fromType: C.self),
                                                    props: P = P(),
                                                    parent: UIComponentProtocol? = nil) -> C {
    assert(Thread.isMainThread)
    _componentInitFromContext = true
    let result: C = pool.component(key: key, construct: C(context: self, key: key))
    result.props = props
    result.parent = parent
    _componentInitFromContext = false
    return result
  }

  public func transientComponent<S, P, C: UIComponent<S, P>>(_ type: C.Type,
                                                             props: P = P(),
                                                             parent: UIComponentProtocol?=nil) -> C{
    assert(Thread.isMainThread)
    _componentInitFromContext = true
    let result: C = C(context: self, key: nil)
    result.props = props
    result.parent = parent
    _componentInitFromContext = false
    return result
  }

  public func suspendComponentRendering() {
    assert(Thread.isMainThread)
    _isRenderSuspended = true
  }

  public func resumeComponentRendering() {
    assert(Thread.isMainThread)
    _isRenderSuspended = false
  }

  /// Many delegates can be registered at the same time and the context hold only weak
  /// references to them.
  public func registerDelegate(_ delegate: UIContextDelegate) {
    assert(Thread.isMainThread)
    delegates.append(UIContextDelegateWeakRef(delegate: delegate))
  }

  public func unregister(_ delegate: UIContextDelegate) {
    assert(Thread.isMainThread)
    delegates = delegates.filter { $0.delegate !== delegate }
  }

  /// Propagates the notification to all of the registered delegates.
  public func didRenderRootComponent(_ component: UIComponentProtocol) {
    guard !isDisposed else {
      disposedWarning()
      return
    }
    for delegate in delegates.compactMap({ $0.delegate }) {
      delegate.setNeedRenderInvoked(on: self, component: component)
    }
  }

  /// Gets rid of the obsolete states.
  public func flushObsoleteState(validKeys: Set<String>) {
    pool.flushObsoleteState(validKeys: validKeys)
  }

  /// Holding struct for a delegate.
  struct UIContextDelegateWeakRef {
    weak var delegate: UIContextDelegate?
  }

  /// Dispose the object and makes it unusable.
  public func dispose() {
    isDisposed = true
    // Disposes all of the components in the pool.
    for component in self.pool.allComponent() {
      component.dispose()
    }
    pool = UIContextPool()
    // Flushes the targets.
    _canvasView = nil
    layoutAnimator = nil
    delegates = []
    _parentContext = nil
  }
}

// MARK: - UIContextPool

public final class UIContextPool {
  private var states: [String: UIStateProtocol] = [:]
  private var components: [String: UIComponentProtocol] = [:]

  /// Retrieves or create a new UI state.
  /// - parameter key: The unique key associated with the new state.
  func state<S: UIStateProtocol>(key: String) -> S {
    assert(Thread.isMainThread)
    if let state = states[key] as? S {
      return state
    }
    guard states[key] == nil else {
      fatalError("Another state with the same key has already been allocated (key: \(key)).")
    }
    let state = S()
    states[key] = state
    return state
  }

  /// Registers a new state in the pool.
  /// - parameter key: The unique key associated with the new state.
  /// - parameter state: The state that is going to be stored in this object pool.
  /// - note: If a state with the same key is already memeber of this object pool, it will be
  /// overriden with the new *state* object passed as argument.
  func store(key: String, state: UIStateProtocol) {
    assert(Thread.isMainThread)
    states[key] = state
  }

  /// Retrieves or create a new UI component.
  /// - parameter key: The unique key associated with this component.
  /// - parameter construct: Instructs the pool on how to instantiate the new component in case
  /// this is not already available in this object pool.
  func component<C: UIComponentProtocol>(key: String, construct: @autoclosure () -> C) -> C {
    assert(Thread.isMainThread)
    if let component = components[key] as? C {
      return component
    }
    guard components[key] == nil else {
      fatalError("Another component with the same key has already been allocated (key: \(key)).")
    }
    let component = construct()
    components[key] = component
    return component
  }

  /// Returns all of the components currently available in the object pool.
  func allComponent() -> [UIComponentProtocol] {
    assert(Thread.isMainThread)
    return components.values.map { $0 }
  }

  // Gets rid of the obsolete states.
  fileprivate func flushObsoleteState(validKeys: Set<String>) {
    assert(Thread.isMainThread)
    states = states.filter { key, _ in validKeys.contains(key) }
    components = components.filter { key, _ in validKeys.contains(key) }
  }
}

public class UIStylesheetContext: UIContext { }
