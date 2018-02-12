import UIKit

open class UIBaseViewController: UIViewController,
                                 UICustomNavigationBarProtocol {
  /// The context for the component hierarchy that is going to be instantiated from the controller.
  /// - note: This can be passed as argument of the view controller constructor.
  public var context: UIContext
  /// The key that is going to be used for the root component.
  public let rootKey: String
  /// The target canvas view for the root component.
  public lazy var canvasView: UIView = {
    return buildCanvasView()
  }()
  /// The layout guide representing the portion of your view that is unobscured by bars
  /// and other content.
  public var shouldUseSafeAreaLayoutGuide: Bool = true
  /// When this is 'true' the component will invoke *setNeedsRender* during the size transition
  /// animation.
  /// - note: There are performance issues with this property being true for ViewControllers
  /// whose root component is a *UITableComponent*.
  public var shouldRenderAlongsideSizeTransitionAnimation: Bool = false
  /// Manages the custom navigation bar (if necessary).
  public lazy var navigationBarManager: UINavigationBarManager = {
    return UINavigationBarManager(context: context)
  }()
  /// Whether this was the first invokation of layout subviews.
  public var firstViewDidLayoutSubviewsInvokation: Bool = true

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

  public init(context: UIContext = UIContext(),
              rootKey: String = String(describing: type(of: self))) {
    self.context = context
    self.rootKey = rootKey
    super.init(nibName: nil, bundle: nil)
  }

  deinit {
    context.dispose()
    logDealloc(type: String(describing: type(of: self)), object: self)
  }

  /// Builds the canvas view for the root component.
  open func buildCanvasView() -> UIView {
    return UIView()
  }

  /// Called after the controller's view is loaded into memory.
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
    if #available(iOS 11.0, *), shouldUseSafeAreaLayoutGuide {
      layoutGuide = view.safeAreaLayoutGuide
    } else {
      layoutGuide = view.compatibleSafeAreaLayoutGuide
    }
    // Constraints.
    navigationBarManager.heightConstraint =
      navigationBarManager.view.heightAnchor.constraint(equalToConstant: 0)
    constraints = [
      navigationBarManager.view.topAnchor.constraint(equalTo: layoutGuide.topAnchor),
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
  }

  /// Renders the viewController.
  open func render() {
    renderNavigationBar()
  }

  /// Called to notify the view controller that its view has just laid out its subviews.
  open override func viewDidLayoutSubviews() {
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

  public func adjustScrollViewContentSizeAfterComponentDidRender() {
    guard let scrollView = self.canvasView as? UIScrollView else { return }
    scrollView.adjustContentSizeAfterComponentDidRender()
  }
}
