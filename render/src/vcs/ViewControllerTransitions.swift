import UIKit

public protocol UISceneViewControllerTransitioning: UIViewControllerProtocol {
  /// The transitioning object in the stage.
  func transitionTargetView() -> UIView
  /// Returns the snapshotted navigation bar.
  func transitionNavigationBar() -> UIView
}

open class UISceneTransition: NSObject, UIViewControllerAnimatedTransitioning {
  /// The main stage view for the transition.
  public lazy var stageView = UIView()
  /// Returns all of the 'UITansitionTarget' associated to the 'from' ViewController.
  private var fromTargets: [UITransitionTarget]?
  /// Returns all of the 'UITansitionTarget' associated to the 'to' ViewController.
  private var toTargets: [UITransitionTarget]?
  /// Returns all of the targets that are transitioning from one scene to the other
  private var transitioningTargets: [(UITransitionTarget, UITransitionTarget)]?
  /// The source navigation bar.
  private var fromNavigationBar: UIView?
  /// The destination navigation bar.
  private var toNavigationBar: UIView?

  /// Returns all of the 'UITansitionTarget' associated to the 'from' ViewController.
  public func fromTargets(context: UIViewControllerContextTransitioning?) -> [UITransitionTarget] {
    if let fromTargets = fromTargets { return fromTargets }
    guard let vc = fromVc(context: context),
          let tvc = vc as? UISceneViewControllerTransitioning else {
      return []
    }
    fromTargets = tvc.transitionTargetView().__snapshotTargetsForTransition()
    return fromTargets!
  }
  /// Returns all of the 'UITansitionTarget' associated to the 'to' ViewController.
  public func toTargets(context: UIViewControllerContextTransitioning?) -> [UITransitionTarget] {
    if let toTargets = toTargets { return toTargets }
    guard let vc = toVc(context: context),
          let tvc = vc as? UISceneViewControllerTransitioning else {
        return []
    }
    toTargets = tvc.transitionTargetView().__snapshotTargetsForTransition()
    return toTargets!
  }
  /// Returns the snapshot of the source ViewController.
  public func fromVcSnapshot(context: UIViewControllerContextTransitioning?) -> UIView {
    guard let vc = fromVc(context: context) else { return UIView() }
    return vc.view.snapshotView(afterScreenUpdates: true) ?? UIView()
  }
  /// Returns the snapshot of the target ViewController.
  public func toVcSnapshot(context: UIViewControllerContextTransitioning?) -> UIView {
    guard let vc = toVc(context: context) else { return UIView() }
    return vc.view.snapshotView(afterScreenUpdates: true) ?? UIView()
  }
  /// Returns the snapshot of the source ViewController.
  public func fromNavigationBarSnapshot(context: UIViewControllerContextTransitioning?) -> UIView {
    if let fromNavigationBar = fromNavigationBar { return fromNavigationBar }
    guard let vc = fromVc(context: context),
          let tvc = vc as? UISceneViewControllerTransitioning else { return UIView() }
    fromNavigationBar = tvc.transitionNavigationBar()
    return fromNavigationBar!
  }
  /// Returns the snapshot of the target ViewController.
  public func toNavigationBarSnapshot(context: UIViewControllerContextTransitioning?) -> UIView {
    if let toNavigationBar = toNavigationBar { return toNavigationBar }
    guard let vc = context?.viewController(forKey: .to),
          let tvc = vc as? UISceneViewControllerTransitioning else { return UIView() }
    toNavigationBar = tvc.transitionNavigationBar()
    return toNavigationBar!
  }
  /// Returns the source ViewController.
  public func fromVc(context: UIViewControllerContextTransitioning?) -> UIViewController? {
    let vc = context?.viewController(forKey: .from)
    if let nvc = vc as? UINavigationController {
      return nvc.topViewController
    } else if let svc = vc as? UISplitViewController {
      return svc.viewControllers.count > 1 ? svc.viewControllers[1] : nil
    }
    return vc
  }
  /// Returns the target ViewController.
  public func toVc(context: UIViewControllerContextTransitioning?) -> UIViewController? {
    let vc = context?.viewController(forKey: .to)
    let _ = vc?.loadViewIfNeeded()
    vc?.view.frame.origin.y += UIApplication.shared.statusBarFrame.size.height
    if let cvc = vc as? UIBaseViewController {
      cvc.render()
    }
    return vc
  }
  /// The main stage for the transition.
  public func containerView(context: UIViewControllerContextTransitioning?) -> UIView {
    return context?.containerView ?? UIView()
  }
  /// Asks your animator object for the duration (in seconds) of the transition animation.
  open func transitionDuration(context: UIViewControllerContextTransitioning?) -> TimeInterval {
    return 0.495
  }
  /// Subclasses to override this method to build the container view for the transition.
  open func transition(context: UIViewControllerContextTransitioning?) {
    guard let containerView = context?.containerView else { return }
    let vc = fromVc(context: context)
    stageView.frame = containerView.bounds
    stageView.backgroundColor = vc?.view.backgroundColor ?? .black
    containerView.addSubview(stageView)
  }
  /// Must be called on animation completion in *transition(context:)* in order to clean up the
  /// stage view and add the target view controller to the window.
  public func completeTransition(context: UIViewControllerContextTransitioning?) {
    guard let view = context?.containerView else { return }
    guard let vc = context?.viewController(forKey: .to) else { return }
    stageView.removeFromSuperview()
    view.addSubview(vc.view)
    context?.completeTransition(true)
  }
  /// Asks your animator object for the duration (in seconds) of the transition animation.
  public func transitionDuration(
    using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return transitionDuration(context: transitionContext)
  }
  /// Tells your animator object to perform the transition animations.
  /// UIKit calls this method when presenting or dismissing a view controller.
  /// Use this method to configure the animations associated with your custom transition.
  /// You can use view-based animations or Core Animation to configure your animations.
  public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    transition(context: transitionContext)
  }

  // MARK: Auto transition

  /// Returns all of the targets that are transitioning from one scene to the other.
  public func transitioningTargets(context: UIViewControllerContextTransitioning?)
    -> [(UITransitionTarget, UITransitionTarget)] {
    if let transitioningTargets = transitioningTargets { return transitioningTargets }
    let from = fromTargets(context: context)
    let to = toTargets(context: context)
    var fromDictionary: [String: UITransitionTarget] = [:]
    var toDictionary: [String: UITransitionTarget] = [:]

    for target in from { fromDictionary[target.key] = target }
    for target in to { toDictionary[target.key] = target }

    var resultDictonary: [String: (UITransitionTarget, UITransitionTarget)] = [:]
    for (key, _) in fromDictionary {
      guard let fromTarget = fromDictionary[key], let toTarget = toDictionary[key] else {
        continue
      }
      resultDictonary[key] = (fromTarget, toTarget)
    }
    var result: [(UITransitionTarget, UITransitionTarget)] = []
    for target in from {
      guard let transitionTarget = resultDictonary[target.key] else { continue }
      result.append(transitionTarget)
    }
    transitioningTargets = result
    return result
  }
  /// Lays out the target snapshot view according the their original position.
  public func setupAutoTransition(context: UIViewControllerContextTransitioning?) {
    let targets = transitioningTargets(context: context)
    let fromNavBar = fromNavigationBarSnapshot(context: context)
    let toNavBar = toNavigationBarSnapshot(context: context)
    toNavBar.alpha = 0
    stageView.addSubview(fromNavBar)
    stageView.addSubview(toNavBar)
    for target in targets {
      let from = target.0
      let to = target.1
      stageView.addSubview(from.view)
      stageView.addSubview(to.view)
      from.view.alpha = 1
      to.view.alpha = 0
    }
  }
}

// MARK: - UIView Extension

public class UITransitionTarget {
  public enum Mode {
    // Take a snapshot from the original view.
    case snapshot
    // Makes a copy of the original view.
    case copy
  }
  /// The original referenced view.
  public weak var original: UIView?
  /// The target (copy or snapshot)
  public weak var view: UIView!
  /// The key for this snapshotted view.
  public let key: String

  init(key: String, view: UIView, mode: Mode) {
    let window = UIApplication.shared.keyWindow ?? UIWindow()
    let frame = view.convert(view.bounds, to: window)
    self.original = view
    switch mode {
    case .snapshot:
      self.view = view.snapshotView(afterScreenUpdates: true)
    default:
      self.view = view.__copyView()
    }
    self.view.frame = frame
    self.key = key
  }
}

extension UIView {
  /// The view will take part to the scene transition.
  @nonobjc public func makeTransitionable(key: String, mode: UITransitionTarget.Mode) {
    switch mode {
    case .snapshot:
      __snapshotKey = key
    case .copy:
      __copyKey = key
    }
  }
  /// Mark this view for snapshotting.
  fileprivate var __snapshotKey: String? {
    get { return objc_getAssociatedObject(self, &_skey) as? String }
    set { objc_setAssociatedObject(self, &_skey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }
  /// Mark this view for snapshotting.
  fileprivate var __copyKey: String? {
    get { return objc_getAssociatedObject(self, &_ckey) as? String }
    set { objc_setAssociatedObject(self, &_ckey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }
  /// Returns all of the views marked for transition snapshotting.
  @nonobjc fileprivate func __snapshotTargetsForTransition() -> [UITransitionTarget] {
    var result: [UITransitionTarget] = []
    var queue: [UIView] = []
    queue.append(self)
    // Breadth first visit of all the subviews.
    while !queue.isEmpty {
      let view = queue.removeFirst()
      queue.append(contentsOf: view.subviews)

      if let key = view.__snapshotKey {
        result.append(UITransitionTarget(key: key, view: view, mode: .snapshot))
      } else if let key = view.__copyKey {
        result.append(UITransitionTarget(key: key, view: view, mode: .copy))
      }
    }
    return result
  }
  /// Make a copy of this view (used for the transition).
  @nonobjc public func __copyView<T: UIView>() -> T {
    let view = NSKeyedUnarchiver.unarchiveObject(with:
      NSKeyedArchiver.archivedData(withRootObject: self)) as! T
    // Copies additional view properties.
    view.cornerRadius = cornerRadius
    view.borderColor = borderColor
    view.borderWidth = borderWidth
    view.depth = depth
    view.shadowColor = shadowColor
    view.shadowOffset = shadowOffset
    view.shadowRadius = shadowRadius
    view.shadowOpacity = shadowOpacity
    view.shapePreset = shapePreset
    return view
  }
}

fileprivate var _ckey: UInt8 = 0
fileprivate var _skey: UInt8 = 0
