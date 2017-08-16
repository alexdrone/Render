import UIKit

public protocol ComponentViewCellDelegate: class {

  /// The component changed its bounds as a result of an internal update.
  func componentDidChangeSize(component: AnyComponentView, indexPath: IndexPath)

  /// Called whenever the component is being layed out.
  func componentOnLayout(component: AnyComponentView, indexPath: IndexPath)
}

final public class ComponentTableViewCell<C: ComponentViewType>: UITableViewCell {

  /// The wrapped component.
  public let component = C()

  /// The current index path for this cell (if applicable).
  public var indexPath: IndexPath?

  /// The tableview associated to this cell.
  public weak var tableView: UITableView?

  /// (Optional) delegate.
  public weak var delegate: ComponentViewCellDelegate?

  public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    if let view = component as? UIView {
      contentView.addSubview(view)
    }
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    if let view = component as? UIView {
      contentView.addSubview(view)
    }
  }

  /// Configure the cell with the component props and state.
  public func configureComponent(in tableView: UITableView,
                                 indexPath: IndexPath,
                                 state: C.StateType? = nil,
                                 options: [RenderOption] = [],
                                 props: (C) -> Void = { _ in }) {

    self.indexPath = indexPath
    self.tableView = tableView
    if let state = state {
      component.state = state
    }
    props(component)
    component.referenceSize = { _ in
      CGSize(width: tableView.bounds.size.width, height: CGFloat.max)
    }
    component.onLayoutCallback = { [weak self] _ in
      self?.onLayout()
      if let component = self?.component {
        self?.delegate?.componentOnLayout(component: component, indexPath: indexPath )
      }
    }
    component.update(options: options)
  }

  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    return component.bounds.size
  }

  open override var intrinsicContentSize: CGSize {
    return component.bounds.size
  }

  func onLayout() {
    contentView.frame.size = component.rootView.bounds.size
    contentView.center = contentView.center
    backgroundColor = component.rootView.backgroundColor
    contentView.backgroundColor = backgroundColor
    guard let tableView = tableView, let indexPath = tableView.indexPath(for: self),
      tableView.rectForRow(at: indexPath).height != component.bounds.size.height else {
        return
    }
    if let delegate = delegate {
      UIView.performWithoutAnimation {
        delegate.componentDidChangeSize(component: component, indexPath: indexPath)
      }
    } else {
      // The default behaviour is reloading the row at the given index path.
      UIView.performWithoutAnimation {
        tableView.reloadRows(at: [indexPath], with: .none)
      }
    }
  }
}

public extension UITableView {

  /// Configure this table view for automatic cell calculation.
  public func withAutomaticDimension(dataSource ds: UITableViewDataSource? = nil) {
    separatorStyle = .none
    rowHeight = UITableViewAutomaticDimension
    if #available(iOS 11, *) {
      estimatedRowHeight = -1;
    } else {
      estimatedRowHeight = 64;
    }
    if let ds = ds {
      dataSource = ds
      reloadData()
    }
  }

  /// Shorthand to return a properly type ComponentTableViewCell.
  public func dequeueReusableComponentCell<T: ComponentViewType>(
      withIdentifier identifier: String = String(describing: type(of: T.self)))
      -> ComponentTableViewCell<T> {

    // ComponentTableViewCell is a wrapper cell around any given component type.
    // We dequeue the cell as it is usually done.
    let cell = dequeueReusableCell(withIdentifier: identifier)
      as? ComponentTableViewCell<T>
      ?? ComponentTableViewCell<T>(style: .default, reuseIdentifier: identifier)
    return cell
  }

  /// Refreshes the component at the given index path.
  public func update(at indexPath: IndexPath) {
    beginUpdates()
    reloadRows(at: [indexPath], with: .fade)
    endUpdates()
  }

  /// Re-renders all the compoents currently visible on screen.
  /// Call this method whenever the table view changes its bounds/size.
  public func updateVisibleComponents() {
    visibleCells
      .flatMap { cell in cell as? InternalComponentCellType }
      .forEach { cell in cell.update(options: [])}
  }
}
