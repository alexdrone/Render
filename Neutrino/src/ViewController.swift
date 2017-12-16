import UIKit

open class UIComponentViewController<C: UIComponentProtocol>: UIViewController {
  /// The context for the component hierarchy that is going to be instantiated from the controller.
  /// - Note: This can be passed as argument of the view controller constructor.
  public let context: UIContext
  /// The key that is going to be used for the root component.
  public let rootKey: String
  /// The root component for this viewController.
  public var component: C!
  /// The target canvas view for the root component.
  public let canvasView: UIView = UIView()
  /// The layout guide representing the portion of your view that is unobscured by bars
  /// and other content.
  public var shouldUseSafeAreaLayoutGuide: Bool = true
  /// Whenever the *TraitCollection* or the screen size changes the default stylesheet is updated
  /// and the component re-rendered.
  /// - Note: This is useful if any of the variables of your js stylesheet queries
  /// *screen()* object for orientation or size classes.
  public var shouldReloadStylesheetOnDisplayMetricsChange: Bool = false
  /// When this is 'true' the component will invoke *setNeedsRender* during the size transition
  /// animation.
  /// - Note: There are performance issues with this property being true for ViewControllers
  /// whose root component is a *UITableComponent*.
  public var shouldRenderAlongsideSizeTransitionAnimation: Bool = false

  private var firstViewDidLayoutSubviewsInvokation: Bool = true

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

  /// Subclasses should override this method and constructs the root component by using the
  /// view controller context.
  /// e.g. return self.context.component(MyComponent.self, key: self.rootKey)
  open func buildRootComponent() -> C {
    fatalError("Subclasses should override this method to build the root component.")
  }

  /// Called after the controller's view is loaded into memory.
  open override func viewDidLoad() {
    super.viewDidLoad()
    edgesForExtendedLayout = []
    component = buildRootComponent()
    canvasView.translatesAutoresizingMaskIntoConstraints = false
    var constraints: [NSLayoutConstraint] = []
    if #available(iOS 11.0, *), shouldUseSafeAreaLayoutGuide {
      constraints = [
        canvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        canvasView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        canvasView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
        canvasView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
      ]
    } else {
      constraints = [
        canvasView.topAnchor.constraint(equalTo: view.topAnchor),
        canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        canvasView.leftAnchor.constraint(equalTo: view.leftAnchor),
        canvasView.rightAnchor.constraint(equalTo: view.rightAnchor),
      ]
    }
    view.addSubview(canvasView)
    NSLayoutConstraint.activate(constraints)
    component.setCanvas(view: canvasView, options: UIComponentCanvasOption.defaults())
  }

  /// Called to notify the view controller that its view has just laid out its subviews.
  open override func viewDidLayoutSubviews() {
    guard firstViewDidLayoutSubviewsInvokation else { return }
    component.setNeedsRender(options: [])
    firstViewDidLayoutSubviewsInvokation = false
  }

  override open func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    let reloadStylesheet = shouldReloadStylesheetOnDisplayMetricsChange
    let renderAlongside = shouldRenderAlongsideSizeTransitionAnimation
    let component: UIComponentProtocol = self.component

    coordinator.animate(alongsideTransition: { _ in
      if renderAlongside {
        component.setNeedsRender(options: [])
      }
    }) { _ in
      if reloadStylesheet || !renderAlongside {
        component.setNeedsRender(options: [])
      }
    }
  }
}
