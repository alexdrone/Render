import UIKit

public protocol ComponentViewCellDelegate: class {

  /// The component changed its bounds as a result of an internal update.
  func componentDidChangeSize(component: AnyComponentView, indexPath: IndexPath)

  /// Called whenever the component is being layed out.
  func componentOnLayout(component: AnyComponentView, indexPath: IndexPath)
}

public class ComponentTableViewCell<C: ComponentViewType>: UITableViewCell {

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
    guard let view = component as? UIView else {
      return
    }
    contentView.addSubview(view)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    guard let view = component as? UIView else {
      return
    }
    contentView.addSubview(view)
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
    component.referenceSize = { CGSize(width: tableView.bounds.size.width, height: CGFloat.max) }
    component.onLayoutCallback = { [weak self] _ in
      self?.onLayout()
      if let component = self?.component {
        self?.delegate?.componentOnLayout(component: component, indexPath: indexPath )
      }
    }
    component.update(options: options)
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
