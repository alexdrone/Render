import UIKit

/// This is a lower lever abstraction compared to *UITableComponent*, useful if you wish to have
/// more fine grain control over some of the *UITableView* primitives.
open class UITableComponentViewController: UITableViewController,
                                           UINodeDelegateProtocol,
                                           UITableComponentCellDelegate {
  /// The context for the component hierarchy that is going to be instantiated from the controller.
  /// - note: This can be passed as argument of the view controller constructor.
  public let context: UIContext
  private let proxyTableView: UIView = UIView()

  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    context = UIContext()
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    logAlloc(type: String(describing: type(of: self)), object: self)
  }

  public required init?(coder aDecoder: NSCoder) {
    context = UIContext()
    super.init(coder: aDecoder)
  }

  public init(context: UIContext = UIContext(),
              rootKey: String = String(describing: type(of: self))) {
    self.context = context
    super.init(nibName: nil, bundle: nil)
  }

  deinit {
    context.dispose()
    logDealloc(type: String(describing: type(of: self)), object: self)
  }

  // MARK: - UIViewController Lifecycle

  /// Called after the controller's view is loaded into memory.
  open override func viewDidLoad() {
    super.viewDidLoad()
    tableView.estimatedRowHeight = -1
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

  // MARK: - UITableViewDataSource

  open override func numberOfSections(in tableView: UITableView) -> Int {
    return numberOfSections()
  }

  open override func tableView(_ tableView: UITableView,
                               numberOfRowsInSection section: Int) -> Int {
    return numberOfComponents(in: section)
  }

  open override func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let id = self.reuseIdentifier(for: indexPath)
    let cell = tableView.dequeueReusableCell(withIdentifier: id) as? UITableComponentCell ??
      UITableComponentCell()
    guard let component = self.component(for: indexPath) else {
      return UITableViewCell()
    }
    cell.delegate = self
    cell.install(component: component, width: tableView.bounds.size.width)
    return cell
  }

  // MARK: - Subclass Overrides

  /// The cell is about to be reused.
  /// - Note: This is the entry point for unmounting the component (if necessary).
  open func cellWillPrepareForReuse(cell: UITableComponentCell) {
    cell.component?.setCanvas(view: proxyTableView, options: [])
  }

  /// Asks the data source to return the number of sections in the table view.
  /// - Note: Subclasses must override this method.
  open func numberOfSections() -> Int {
    return 1
  }

  /// Tells the data source to return the number of rows in a given section of a table view.
  /// - Note: Subclasses must override this method.
  open func numberOfComponents(in section: Int) -> Int {
    return 0
  }

  /// Returns the desired reuse identifier for the cell with the index path passed as argument.
  /// - Note: Subclasses must override this method.
  open func reuseIdentifier(for indexPath: IndexPath) -> String {
    return "undefined"
  }

  /// Must return the desired component for at the given index path.
  /// - Note: Subclasses must override this method.
  open func component(for indexPath: IndexPath) -> UIComponentProtocol? {
    return nil
  }

  // MARK: - UINodeDelegateProtocol

  /// The backing view of *node* just got rendered and added to the view hierarchy.
  /// - parameter view: The view that just got installed in the view hierarchy.
  open func nodeDidMount(_ node: UINodeProtocol, view: UIView) { }

  /// The backing view of *node* is about to be layed out.
  /// - parameter view: The view that is about to be configured and layed out.
  open func nodeWillLayout(_ node: UINodeProtocol, view: UIView) {
    tableView.beginUpdates()
  }

  /// The backing view of *node* just got layed out.
  /// - parameter view: The view that has just been configured and layed out.
  open func nodeDidLayout(_ node: UINodeProtocol, view: UIView) {
    tableView.endUpdates()
  }
}
