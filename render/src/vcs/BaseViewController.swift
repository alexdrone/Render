import UIKit

open class UIBaseViewController:
  UIViewController,
  UIGestureRecognizerDelegate,
  UICustomNavigationBarProtocol {
  /// The context for the component hierarchy that is going to be instantiated from the controller.
  /// - note: This can be passed as argument of the view controller constructor.
  public var context: UIContext
  /// The key that is going to be used for the root component.
  public var rootKey: String
  /// The target canvas view for the root component.
  /// This is the view that is going to be used from the component to render its view hierarchy.
  /// - note: This view is layed out using the safe area guide, if you want it to cover the whole
  /// surface of the ViewController set *shouldUseSafeAreaLayoutGuide* to 'false'.
  public lazy var canvasView: UIView = {
    return buildCanvasView()
  }()
  /// Whether the canvas view should be inscribed in the safe area.
  /// The safe area guaide is the  layout guide representing the portion of your view that is
  /// unobscured by bars and other content.
  public var shouldUseSafeAreaLayoutGuide: Bool = true
  /// When this is 'true' the component will invoke *setNeedsRender* during the size transition
  /// animation (resulting in an animation).
  public var shouldRenderAlongsideSizeTransitionAnimation: Bool = true
  /// Manager for the custom (component-based) navigation bar.
  /// If you wish to use the component-based navigation bar in your ViewController, you simply have
  /// to assign your *UINavigationBarComponent* subclass to the manager's component. e.g.
  ///
  ///     navigationBarManager.component = context?.component(MyBarComponent.self, key: "navbar")
  ///
  /// You can use the default component by calling *makeDefaultNavigationBarComponent* e.g.
  ///
  ///     navigationBarManager.makeDefaultNavigationBarComponent()
  ///
  /// You can then customize the navigation bar component by accessing to its 'props' - see
  /// **navigationBarManager.props**.
  ///
  ///     navigationBarManager.props.title = "Your title"
  ///     navigationBarManager.props.style.backgroundColor = .red
  ///
  /// - note: Customize your navigation bar in *viewDidLoad* before calling the *super*
  /// implementation.
  public lazy var navigationBarManager: UINavigationBarManager = {
    return UINavigationBarManager(context: context)
  }()
  /// Whether this was the first invokation of layout subviews.
  /// - note: This is used to have a preliminary render call to the component hierarchy.
  public var firstViewDidLayoutSubviewsInvokation: Bool = true
  /// The view that is currently focused and will take part to the upcoming ViewController
  /// transition, if *nil* the canvas view is returned.
  public weak var currentTransitionTargetView: UIView?

  /// Returns a newly initialized view controller with the nib file in the specified bundle.
  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    context = UIContext()
    rootKey = String(describing: type(of: self))
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    logAlloc(type: String(describing: type(of: self)), object: self)
  }

  public required init?(coder aDecoder: NSCoder) {
    context = UIContext()
    rootKey = String(describing: type(of: self))
    super.init(coder: aDecoder)
  }

  deinit {
    context.dispose()
    logDealloc(type: String(describing: type(of: self)), object: self)
  }

  /// Builds the canvas view for the root component.
  /// Override this method if you wish to provide a different *UIView* subclass as your main canvas.
  /// - note: *UIScrollableComponentViewController* override this method by providing a
  /// *UIScrollView* canvas.
  open func buildCanvasView() -> UIView {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }

  /// Called after the controller's view is loaded into memory.
  /// - note: Customize your navigation bar in *viewDidLoad* before calling the *super*
  /// implementation.
  open override func viewDidLoad() {
    super.viewDidLoad()
    // Necessary only if the view controller has a custom navigation bar.
    // 'navigationBarComponent' is not nil.
    initializeNavigationBarIfNecessary()
    edgesForExtendedLayout = []
    canvasView.translatesAutoresizingMaskIntoConstraints = false
    // Layout guides.
    var constraints: [NSLayoutConstraint] = []
    var layoutGuide: UILayoutGuideProvider
    var topAnchor: NSLayoutYAxisAnchor
    if #available(iOS 11.0, *), shouldUseSafeAreaLayoutGuide {
      layoutGuide = view.safeAreaLayoutGuide
      topAnchor = layoutGuide.topAnchor
    } else {
      layoutGuide = view
      topAnchor = self.topLayoutGuide.topAnchor
    }

    // Constraints.
    navigationBarManager.heightConstraint =
      navigationBarManager.view.heightAnchor.constraint(equalToConstant: 0)
    constraints = [
      navigationBarManager.view.topAnchor.constraint(equalTo: topAnchor),
      navigationBarManager.view.leftAnchor.constraint(equalTo: layoutGuide.leftAnchor),
      navigationBarManager.view.rightAnchor.constraint(equalTo: layoutGuide.rightAnchor),
      navigationBarManager.heightConstraint!,
      canvasView.topAnchor.constraint(equalTo: navigationBarManager.view.bottomAnchor),
      canvasView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor),
      canvasView.leftAnchor.constraint(equalTo: layoutGuide.leftAnchor),
      canvasView.rightAnchor.constraint(equalTo: layoutGuide.rightAnchor),
    ]
    // Configure the view hierarchy.
    view.addSubview(canvasView)
    view.addSubview(navigationBarManager.view)
    NSLayoutConstraint.activate(constraints)

    // Enables interactive pop gesture by default.
    navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    navigationController?.interactivePopGestureRecognizer?.delegate = self;
  }

  /// Asks the delegate if a gesture recognizer should be required to fail by another
  /// gesture recognizer.
  /// - note: Override this method if your viewController has a gesture conflicting with the
  /// interactive pop gesture recognizer.
  public func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }

  /// Renders the viewController canvas.
  /// - note: The navigation bar is also being re-rendered.
  open func render(options: [UIComponentRenderOption] = []) {
    renderNavigationBar()
  }

  /// Called to notify the view controller that its view has just laid out its subviews.
  open override func viewDidLayoutSubviews() {
    view.backgroundColor = canvasView.backgroundColor
    guard firstViewDidLayoutSubviewsInvokation else {
      return
    }
    render()
    firstViewDidLayoutSubviewsInvokation = false
  }

  /// Called when the view controller is appearing on the stack.
  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if navigationBarManager.hasCustomNavigationBar {
      navigationController?.isNavigationBarHidden = true
    }
    // Render on appearance transition required on iOS 10.
    if #available(iOS 11.0, *) { /* nop */} else { render() }
  }

  /// Notifies the view controller that its view was added to a view hierarchy.
  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Render on appearance transition required on iOS 10.
    if #available(iOS 11.0, *) { /* nop */} else { render() }
  }

  /// Called when the view controller is disappearing from the stack.
  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.isNavigationBarHidden = navigationBarManager.wasNavigationBarHidden
  }
}

extension UIBaseViewController: UISceneViewControllerTransitioning {
  /// Returns the view used for view controller transitioning.
  open func transitionTargetView() -> UIView {
    return currentTransitionTargetView ?? canvasView
  }

  /// Returns the snapshotted navigation bar.
  open func transitionNavigationBar() -> UIView {
    if navigationBarManager.component != nil {
      let view = navigationBarManager.view.snapshotView(afterScreenUpdates: true) ?? UIView()
      view.frame.origin.y = navigationBarManager.view.frame.origin.y
      return view
    }
    guard let nv = navigationController else { return UIView() }
    return nv.navigationBar.snapshotView(afterScreenUpdates: true) ?? UIView()
  }
}

public protocol UIViewControllerProtocol: class {
  /// The view controller view.
  var view: UIView! { get }
}

extension UIViewController: UIViewControllerProtocol { }
