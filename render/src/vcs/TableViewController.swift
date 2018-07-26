import UIKit

open class UITableComponentViewController:
  UIBaseViewController,
  UITableViewDelegate,
  UITableViewDataSource,
  UITableViewDataSourcePrefetching,
  UINodeDelegateProtocol,
  UITableComponentCellDelegate,
  UIContextDelegate {
  /// The canvas view for this ViewController.
  public var tableView: UITableView { return canvasView as! UITableView }
  /// Fades in the content of the cell when the scroll reveals it.
  /// - note: Defaul is 'true'.
  public var shouldApplyScrollRevealTransition: Bool = false
  /// Used to populate the table view withouth overriding *tableView:_:cellForRowAt*.
  /// - note: This is a simple declarative approach to table definition that can be used for
  /// simple lists (with a single section) - override *tableView:_:cellForRowAt* for more custom
  /// behaviours.
  public var cellDescriptors: [UIComponentCellDescriptor] = []

  // Private.
  private let proxyTableView: UIView = UIView()
  private var currentCellHeights: [Int: CGFloat] = [:]
  private var skippedNodesFromLayoutCallbacks = Set<Int>()
  private var shouldSkipAllLayoutCallbacks: Bool = false
  private var cellContext: UICellContext { return context as! UICellContext }

  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    context = UICellContext()
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    context = UICellContext()
    commonInit()
  }

  deinit {
    context.unregister(self)
    context.dispose()
    logDealloc(type: String(describing: type(of: self)), object: self)
  }

  /// Shared initialization.
  private func commonInit() {
    logAlloc(type: String(describing: type(of: self)), object: self)
    context.registerDelegate(self)
    cellContext._associatedTableViewController = self
  }

  /// Builds the canvas view for the root component.
  /// - note: The canvas view for this viewController is a *UITableView*
  open override func buildCanvasView() -> UIView {
    let tableView = UITableView()
    tableView.delegate = self
    tableView.dataSource = self
    tableView.prefetchDataSource = self
    tableView.contentInset = UIEdgeInsets.zero
    tableView.translatesAutoresizingMaskIntoConstraints = false
    return tableView
  }

  /// - note: Override this method if you desire to run custom logic whenever a component has
  /// been rendered.
  open func setNeedRenderInvoked(on context: UIContextProtocol, component: UIComponentProtocol) {
  }

  /// Used to populate the table view withouth overriding *tableView:_:cellForRowAt*.
  /// - note: This is a simple declarative approach to table definition that can be used for
  /// simple lists (with a single section) - override *tableView:_:cellForRowAt* for more custom
  /// behaviours.
  open func renderCellDescriptors() -> [UIComponentCellDescriptor] {
    return []
  }

  /// - note: This triggers reload data to be called on the 'tableView'.
  open override func render(options: [UIComponentRenderOption] = []) {
    super.render()
    reloadData()
  }

  /// Reloads the rows and sections of the table view.
  /// Call this method to reload all the data that is used to construct the table, including cells,
  /// section headers and footers, index arrays, and so on.
  open func reloadData() {
    cellDescriptors = renderCellDescriptors()
    tableView.reloadData()
  }

  /// Render the components visible on screen with the 'options' passed as argument.
  /// - parameter invalidateTableViewLayout: 'true' if you want to force the *UITableView* to
  /// recompute its cells heights, 'false' otherwise.
  open func setNeedsRenderVisibleComponents(
    options: [UIComponentRenderOption] = [],
    invalidateTableViewLayout: Bool = false
  ) -> Void {
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
    tableView.rowHeight = UITableView.automaticDimension
    tableView.separatorStyle = .none
  }

  /// Called to notify the view controller that its view has just laid out its subviews.
  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    proxyTableView.frame = tableView.bounds
  }

  /// Notifies the container that the size of its view is about to change.
  override open func viewWillTransition(
    to size: CGSize,
    with coordinator: UIViewControllerTransitionCoordinator
  ) -> Void {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { _ in
    }) { [weak self] _ in
      self?.reloadData()
    }
  }

  /// Tells the data source to return the number of rows in a given section of a table view.
  /// - note: Must be overriden if
  @objc open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return cellDescriptors.count
  }

  /// Asks the data source for a cell to insert in a particular location of the table view.
  /// If you wish to use a *UIComponentTableViewCell* a typical implementation of this method would
  /// be as follow:
  ///
  ///    let component = context.component(MyComponent.self, ...)
  ///    return dequeueCell(forComponent: component)
  ///
  /// - note: Override this method if you don't want to rely on the *cellDescriptors* property.
  @objc open func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    guard cellDescriptors.count > indexPath.row,
      let component = cellDescriptors[indexPath.row].component else { return UITableViewCell() }
    let id = cellDescriptors[indexPath.row].reuseIdentifier
    return dequeueCell(component: component, withReuseIdentifier: id)
  }

  @objc open func tableView(_ tableView: UITableView, prefetchRowsAt: [IndexPath]) {
    for indexPath in prefetchRowsAt where cellDescriptors.count > indexPath.row {
      let _ = cellDescriptors[indexPath.row].component?.asNode()
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

  /// Dequeues a *UITableComponentCell* for the component passed as argument.
  public func dequeueCell(
    component: UIComponentProtocol,
    withReuseIdentifier id: String
  ) -> UITableComponentCell {
    let cell = dequeueCell(withReuseIdentifier: id)
    component.delegate = self
    cell.install(component: component, width: tableView.bounds.size.width)
    return cell
  }

  /// Shorthand for *dequeueCell(component:withReuseIdentifier:)*
  public func dequeueCell<T:UIComponentProtocol>(forComponent component: T) -> UITableComponentCell{
    return dequeueCell(component: component,
                       withReuseIdentifier: String(describing: type(of: component)))
  }

  public func defaultKey(forIndexPath indexPath: IndexPath) -> String {
    return "\(indexPath.section):\(indexPath.row)"
  }

  // MARK: - UITableSectionHeader

  /// *Optional*. Override this method to provide a custom view for your table view header.
  /// Use the *UIView.install* helper method if you wish to return a component for this
  /// section header. e.g.
  ///
  ///     UIView().install(component: myComponent, size: tableView.bounds.size)
  ///
  /// Section headers are not compatible with *expandable* navigation bars.
  /// Configure your navigation bar as follows if you wish to use section headers:
  ///
  ///     navigationBarManager.component?.props.expandable = false
  ///
  open func viewForHeader(inSection section: Int) -> UIView? {
    return nil
  }

  /// Asks the delegate for a view object to display in the header of the specified section of
  /// the table view.
  @objc open func tableView(
    _ tableView: UITableView,
    viewForHeaderInSection section: Int
  ) -> UIView?{
    return viewForHeader(inSection: section)
  }

  /// Asks the delegate for the height to use for the header of a particular section.
  @objc open func tableView(
    _ tableView: UITableView,
    heightForHeaderInSection section: Int
    ) -> CGFloat {
    return viewForHeader(inSection: section)?.bounds.size.height ?? 0
  }

  /// Tells the delegate when the user scrolls the content view within the receiver.
  @objc open func scrollViewDidScroll(_ scrollView: UIScrollView) {
    navigationBarDidScroll(scrollView)
  }

  // MARK: - Highlight and Selection

  /// Updates the 'isHighlighted' status for the props passed as argument and re-render the
  /// visible components
  /// Call this in *tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath)*.
  public func didHighlightRowAt(props: [UITableCellProps], indexPath: IndexPath) {
    for (row, prop) in props.enumerated() { prop.isHighlighted = row == indexPath.row }
    setNeedsRenderVisibleComponents()
  }

  /// Call this in *tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)*.
  public func didSelectRowAt(props: [UITableCellProps], indexPath: IndexPath) {
    currentTransitionTargetView = tableView.cellForRow(at: indexPath)
    props[indexPath.row].onCellSelected?()
  }

  // MARK: -

  /// The cell is about to be reused.
  /// - note: This is the entry point for unmounting the component (if necessary).
  @objc open func cellWillPrepareForReuse(cell: UITableComponentCell) {
    cell.component?.setCanvas(view: proxyTableView, options: [])
  }

  /// Override this method to provide a custom cell reveal transition on scroll.
  /// - note: Make sure *shouldApplyScrollRevealTransition* is 'true' for your view controller.
  open func applyScrollRevealTransition(view: UIView) {
    if tableView.isDragging || tableView.isDecelerating {
      let alpha = view.alpha
      let options: UIView.AnimationOptions = [
        UIView.AnimationOptions.allowUserInteraction,
        UIView.AnimationOptions.beginFromCurrentState]
      view.alpha = 0
      UIView.animate(
        withDuration: 0.3,
        delay: 0,
        options: options,
        animations: { view.alpha = alpha },
        completion: { _ in view.alpha = alpha })
    }
  }

  // MARK: - UINodeDelegateProtocol

  open func nodeDidMount(_ node: UINodeProtocol, view: UIView) {
    guard shouldApplyScrollRevealTransition else { return }
    applyScrollRevealTransition(view: view)
  }

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
    let size = _associatedTableViewController?.tableView.bounds.size ?? .zero
    if size == .zero {
      return UIScreen.main.bounds.size
    }
    return size
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
  /// The node currently associated to this cell.
  public var component: UIComponentProtocol?
  /// *Internal only*
  public weak var delegate: UITableComponentCellDelegate?

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
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
  public func install(component: UIComponentProtocol, width: CGFloat) {
    let _ = component.asNode()
    mount(component: component, width: width)
  }

  func mount(component: UIComponentProtocol, width: CGFloat) {
    self.component = component
    component.setCanvas(view: contentView, options: [])

    // We purposely won't re-generate the node (by calling *asNode()*) because this has already
    // been called in the 'heightForRowAt' delegate method.
    // We just install the node in the right view hierarchy.
    component.root.reconcile(
      in: contentView,
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
  /// - note: The size is inferred from the component size.
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

// MARK: - Cell Descriptor

final public class UIComponentCellDescriptor {
  /// The component that must be installed in the cell.
  public private(set) weak var component: UIComponentProtocol?
  /// The cell reuse identifier (optional, automatically inferred).
  public let reuseIdentifier: String

  public init<T: UIComponentProtocol>(
    component: T,
    reuseIdentifier: String? = nil
  ) {
    let id = reuseIdentifier ?? String(describing: type(of: component))
    self.reuseIdentifier = id
    self.component = component
  }
}
