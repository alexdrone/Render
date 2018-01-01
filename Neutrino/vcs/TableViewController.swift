import UIKit

/// This is a lower lever abstraction compared to *UITableComponent*, useful if you wish to have
/// more fine grain control over some of the *UITableView* primitives.
open class UITableComponentViewController: UITableViewController,
                                           UINodeDelegateProtocol,
                                           UITableComponentCellDelegate,
                                           UIContextDelegate {
  /// Fades in the content of the cell when the scroll reveals it.
  /// - note: Defaul is 'true'.
  public var shouldApplyScrollRevealTransition: Bool = false
  /// The context for the component hierarchy that is going to be instantiated from the controller.
  /// - note: This can be passed as argument of the view controller constructor.
  public let context: UIContext
  private let proxyTableView: UIView = UIView()
  private var currentCellHeights: [Int: CGFloat] = [:]
  private var shouldSkipNodeLayoutCallbacks = Set<Int>()

  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    context = UIContext()
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    context = UIContext()
    super.init(coder: aDecoder)
    commonInit()
  }

  public init(context: UIContext = UIContext(),
              rootKey: String = String(describing: type(of: self))) {
    self.context = context
    super.init(nibName: nil, bundle: nil)
    commonInit()
  }

  deinit {
    context.unregister(self)
    context.dispose()
    logDealloc(type: String(describing: type(of: self)), object: self)
  }

  private func commonInit() {
    logAlloc(type: String(describing: type(of: self)), object: self)
    context.registerDelegate(self)
    context._associatedTableViewController = self
  }

  /// - note: Override this method if you desire to run custom logic whenever a component has
  /// been rendered.
  open func setNeedRenderInvoked(on context: UIContextProtocol, component: UIComponentProtocol) {
  }

  /// Reloads the rows and sections of the table view.
  open func reloadData() {
    tableView.reloadData()
  }

  // MARK: - UIViewController Lifecycle

  /// Called after the controller's view is loaded into memory.
  open override func viewDidLoad() {
    super.viewDidLoad()
    if #available(iOS 11.0, *) {
      tableView.estimatedRowHeight = -1
    } else {
      tableView.estimatedRowHeight = 64
    }
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.separatorStyle = .none
  }

  /// Called to notify the view controller that its view has just laid out its subviews.
  open override func viewDidLayoutSubviews() {
    proxyTableView.frame = tableView.bounds
  }

  /// Notifies the container that the size of its view is about to change.
  override open func viewWillTransition(to size: CGSize,
                                        with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { _ in
    }) { [weak self] _ in
      self?.tableView.reloadData()
    }
  }

  // MARK: - UITableViewDataSource Helper

  /// Returns the *UITableComponentCell* for the identifier passed as argument.
  public func dequeueCell(withReuseIdentifier id: String) -> UITableComponentCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: id) as? UITableComponentCell ??
      UITableComponentCell()
    cell.delegate = self
    return cell
  }

  /// Shorthand for *dequeueCell(withReuseIdentifier:)*
  public func dequeueCell<T:UIComponentProtocol>(forComponent component: T) -> UITableComponentCell{
    let cell = dequeueCell(withReuseIdentifier: String(describing: type(of: component)))
    component.delegate = self
    cell.install(component: component, width: tableView.bounds.size.width)
    return cell
  }

  // MARK: - Subclass Overrides

  /// The cell is about to be reused.
  /// - note: This is the entry point for unmounting the component (if necessary).
  open func cellWillPrepareForReuse(cell: UITableComponentCell) {
    cell.component?.setCanvas(view: proxyTableView, options: [])
  }

  /// Override this method to provide a custom cell reveal transition on scroll.
  /// - note: Make sure *shouldApplyScrollRevealTransition* is 'true' for your view controller.
  open func applyScrollRevealTransition(view: UIView) {
    if tableView.isDragging || tableView.isDecelerating {
      let alpha = view.alpha
      view.alpha = 0
      UIView.animate(withDuration: 0.3,
                     delay: 0,
                     options: [.allowUserInteraction, .beginFromCurrentState],
                     animations: { view.alpha = alpha },
                     completion: { _ in view.alpha = alpha })
    }
  }

  // MARK: - UINodeDelegateProtocol

  /// The backing view of *node* just got rendered and added to the view hierarchy.
  /// - parameter view: The view that just got installed in the view hierarchy.
  open func nodeDidMount(_ node: UINodeProtocol, view: UIView) {
    guard shouldApplyScrollRevealTransition else { return }
    applyScrollRevealTransition(view: view)
  }

  /// The backing view of *node* is about to be layed out.
  /// - parameter view: The view that is about to be configured and layed out.
  open func nodeWillLayout(_ node: UINodeProtocol, view: UIView) {
    let old = currentCellHeights[view.tag] ?? CGFloat.undefined
    guard old != view.bounds.size.height else {
      shouldSkipNodeLayoutCallbacks.insert(view.tag)
      return
    }
    currentCellHeights[view.tag] = view.bounds.size.height
    guard !context._preventTableUpdates else {
      return
    }
    // This is to mitigate rdar://19581195
    // Self sizing table view cells jump when scrolling up.
    CATransaction.begin()
    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
    tableView.beginUpdates()
  }

  /// The backing view of *node* just got layed out.
  /// - parameter view: The view that has just been configured and layed out.
  open func nodeDidLayout(_ node: UINodeProtocol, view: UIView) {
    guard !shouldSkipNodeLayoutCallbacks.contains(view.tag) else {
      shouldSkipNodeLayoutCallbacks.remove(view.tag)
      return
    }
    guard !context._preventTableUpdates else {
      context._preventTableUpdates = false
      return
    }
    tableView.endUpdates()
    CATransaction.commit()
  }
}
