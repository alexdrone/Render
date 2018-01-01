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
  // Private.
  private let proxyTableView: UIView = UIView()
  private var currentCellHeights: [Int: CGFloat] = [:]
  private var skippedNodesFromLayoutCallbacks = Set<Int>()
  private var shouldSkipAllLayoutCallbacks: Bool = false

  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    context = UICellContext()
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    context = UICellContext()
    super.init(coder: aDecoder)
    commonInit()
  }

  public init(context: UIContext = UICellContext(),
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

  /// Render the components visible on screen with the 'options' passed as argument.
  /// - parameter invalidateTableViewLayout: 'true' if you want to force the *UITableView* to
  /// recompute its cells heights, 'false' otherwise.
  open func setNeedsRenderVisibleComponents(options: [UIComponentRenderOption] = [],
                                            invalidateTableViewLayout: Bool = false) {
    let components = context.pool.allComponent().filter { $0.canvasView != nil }
    shouldSkipAllLayoutCallbacks = !invalidateTableViewLayout
    for component in components {
      component.setNeedsRender(options: options)
    }
    shouldSkipAllLayoutCallbacks = false
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

  public func defaultKey(forIndexPath indexPath: IndexPath) -> String {
    return "\(indexPath.section):\(indexPath.row)"
  }

  // MARK: - UITableSectionHeader

  /// *Optional*. Override this method to provide a custom view for your table view header.
  /// - note: Use the *UIView.install* helper method if you wish to return a component for this
  /// section header. e.g.
  /// *UIView().install(component: myComponent, size: tableView.bounds.size)*
  open func viewForHeader(inSection section: Int) -> UIView? {
    return nil
  }

  /// Asks the delegate for a view object to display in the header of the specified section of
  /// the table view.
  open override func tableView(_ tableView: UITableView,
                               viewForHeaderInSection section: Int) -> UIView?{
    return viewForHeader(inSection: section)
  }

  /// Asks the delegate for the height to use for the header of a particular section.
  open override func tableView(_ tableView: UITableView,
                               heightForHeaderInSection section: Int) -> CGFloat {
    return viewForHeader(inSection: section)?.bounds.size.height ?? 0
  }

  // MARK: -

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
    guard !shouldSkipAllLayoutCallbacks else {
      return
    }
    let old = currentCellHeights[view.tag] ?? CGFloat.undefined
    guard old != view.bounds.size.height else {
      skippedNodesFromLayoutCallbacks.insert(view.tag)
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
    guard !shouldSkipAllLayoutCallbacks else {
      return
    }
    guard !skippedNodesFromLayoutCallbacks.contains(view.tag) else {
      skippedNodesFromLayoutCallbacks.remove(view.tag)
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

// MARK: - UITableCellProps Baseclass

open class UITableCellProps: UIPropsProtocol {
  public required init() { }
  /// Cell title.
  public var title = String()
  /// Cell subtitle.
  public var subtitle = String()
  /// Automatically set to 'true' whenever the cell is being highlighted.
  public var isHighlighted: Bool = false
  /// The closure that is going to be executed whenever the cell is selected.
  public var onCellSelected: (() -> Void)? = nil

  public init(title: String, subtitle: String = "", onCellSelected: @escaping () -> Void) {
    self.title = title
    self.subtitle = subtitle
    self.onCellSelected = onCellSelected
  }
}

// MARK: - UICellContext

/// Component that are embedded in cells have a different context.
public final class UICellContext: UIContext {
  /// Layout animator is not available for cells.
  public override var layoutAnimator: UIViewPropertyAnimator? {
    get { return nil }
    set { }
  }

  public override var canvasSize: CGSize {
    guard let context = _parentContext as? UIContext else {
      return .zero
    }
    return context.canvasSize
  }

  public override func flushObsoleteState(validKeys: Set<String>) {
    /// The lifetime of the cells is diffirent from traditional components due to recycling
    /// and managed from *UITableComponent*.
  }
}

// MARK: - UITableViewComponentCell

public protocol UITableComponentCellDelegate: class {
  /// The cell is about to be reused.
  /// - note: This is the entry point for unmounting the component (if necessary).
  func cellWillPrepareForReuse(cell: UITableComponentCell)
}

public class UITableComponentCell: UITableViewCell {
  /// The node currently associated to this view.
  public var component: UIComponentProtocol?
  public weak var delegate: UITableComponentCellDelegate?

  public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Prepares a reusable cell for reuse by the table view's delegate.
  public override func prepareForReuse() {
    delegate?.cellWillPrepareForReuse(cell: self)
  }

  /// Install the component passed as argument in the *UITableViewCell*'s view hierarchy.
  /// - note: This API is not called from *UITableComponent*.
  public func install(component: UIComponentProtocol, width: CGFloat) {
    let _ = component.asNode()
    mount(component: component, width: width)
  }

  func mount(component: UIComponentProtocol, width: CGFloat) {
    self.component = component
    component.setCanvas(view: contentView, options: [])

    // We purposely wont re-generate the node (by calling *asNode()*) because this has already
    // been called in the 'heightForRowAt' delegate method.
    // We just install the node in the right view hierarchy.
    component.root.reconcile(in: contentView,
                             size: CGSize(width: width, height: CGFloat.max),
                             options: [.preventDelegateCallbacks])

    guard let componentView = contentView.subviews.first else {
      return
    }
    contentView.frame.size = componentView.bounds.size
    contentView.backgroundColor = componentView.backgroundColor
    backgroundColor = componentView.backgroundColor
  }

  /// Asks the view to calculate and return the size that best fits the specified size.
  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    guard let component = component else {
      return .zero
    }
    mount(component: component, width: size.width)
    return contentView.frame.size
  }
}

extension UIComponent {
  /// 'true' if this component is being used in a tableview or a collection view.
  var isEmbeddedInCell: Bool { return self.context is UICellContext }
}
