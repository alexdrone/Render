import Foundation
import UIKit

// MARK: - Cell protocol

public protocol ComponentCellType: class  {

  /// The cell contentview.
  var contentView: UIView { get }

  /// The component view wrapped by this cell.
  var componentView: AnyComponentView? { get set }

  /// Sets the component state.
  func set(state: Render.StateType, options: [RenderOption])

  /// Calls render on the underlying component view. See: 'render(in:options)' in ComponentView.
  func update(options: [RenderOption])

  /// Invoked whenever the component is being laid out.
  func onLayout(duration: TimeInterval)

  /// Mount the component passed as argument in the cell.
  func mountComponentIfNecessary(isStateful: Bool,
                                 _ component: @autoclosure () -> AnyComponentView)
}

extension ComponentCellType where Self: UIView {

  public func mountComponentIfNecessary(isStateful: Bool = true,
                                        _ component: @autoclosure () -> AnyComponentView) {
    func configure(component: AnyComponentView?) {
      component?.referenceSize = { [weak self] in
        let width = self?.bounds.size.width ?? UIScreen.main.bounds.size.width
        let height: CGFloat = CGFloat.max
        return CGSize(width: width, height: height)
      }
      component?.onLayoutCallback = onLayout
    }
    configure(component: componentView)
    guard componentView == nil || isStateful else {
      return
    }
    componentView = component()
    if let componentView = componentView as? UIView {
      contentView.addSubview(componentView)
    }
    configure(component: componentView)
    clipsToBounds = true
  }

  /// Forward the invokation to update to the owned component view.
  public func update(options: [RenderOption] = []) {
    if let tableViewCell = self as? UITableViewCell {
      tableViewCell.selectionStyle = .none
    }
    componentView?.update(options: options)
  }

  func commonOnLayout(duration: TimeInterval) {
    guard let component = self.componentView, let view = self.componentView as? UIView else {
      return
    }
    contentView.frame.size = component.rootView.bounds.size
    view.center = contentView.center
    backgroundColor = component.rootView.backgroundColor
    contentView.backgroundColor = backgroundColor
  }

  func commonSizeThatFits(_ size: CGSize) -> CGSize {
    return componentView?.sizeThatFits(size) ?? CGSize.zero
  }

  var commonIntrinsicContentSize: CGSize {
    return componentView?.intrinsicContentSize ?? CGSize.zero
  }

}

extension ComponentCellType where Self: UITableViewCell {

  /// Called whenever the component finished to be rendered and updated its size.
  public func onLayout(duration: TimeInterval) {
    guard let component = componentView else {
      return
    }
    commonOnLayout(duration: duration)
    let table = superview as? UITableView
    guard component.bounds.size.height != self.bounds.size.height else {
      return
    }
    if let indexPath = table?.indexPath(for: self) {
      UIView.performWithoutAnimation {
        table?.reloadRows(at: [indexPath], with: .none)
      }
    }
  }
}

extension ComponentCellType where Self: UICollectionViewCell {

  /// Called whenever the component finished to be rendered and updated its size.
  public func onLayout(duration: TimeInterval) {
    let collectionView = superview as? UICollectionView
    commonOnLayout(duration: duration)
    if let indexPath = collectionView?.indexPath(for: self) {
      collectionView?.reloadItems(at: [indexPath])
    } else {
      print("A component cell just got updated but the indexpath doesn't seem to be available.")
    }
  }
}

// MARK: - UITableViewCell

/// Wraps a component in a UITableViewCell.
open class ComponentTableViewCell: UITableViewCell, ComponentCellType  {

  /// Sets the component state.
  public func set(state: Render.StateType, options: [RenderOption] = []) {
    componentView?.set(state: state, options: options)
  }

  /// The component view wrapped by this cell.
  /// Internal use only. Use 'mountComponentIfNecessary' to add a component to this cell.
  public var componentView: AnyComponentView?

  public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    return commonSizeThatFits(size)
  }

  open override var intrinsicContentSize: CGSize {
    return commonIntrinsicContentSize
  }
}

// MARK: - UICollectionViewCell

/// Wraps a component in a UICollectionViewCell.
open class ComponentCollectionViewCell: UICollectionViewCell, ComponentCellType  {

  /// Sets the component state.
  public func set(state: Render.StateType,
                  options: [RenderOption] = []) {
    componentView?.set(state: state, options: options)
  }

  /// The component view wrapped by this cell.
  /// Internal use only. Use 'mountComponentIfNecessary' to add a component to this cell.
  public var componentView: AnyComponentView?

  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    return componentView?.bounds.size ?? CGSize.zero
  }

  open override var intrinsicContentSize: CGSize {
    return  componentView?.bounds.size ?? CGSize.zero
  }
}

//MARK: - Extensions

extension UITableView {

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
      .flatMap { cell in cell as? ComponentCellType }
      .forEach { cell in cell.update(options: [])}
  }
}

extension UICollectionView {

  ///  Refreshes the component at the given index path.
  public func update(at indexPath: IndexPath) {
    performBatchUpdates({ self.reloadItems(at: [indexPath]) }, completion: nil)
  }

  /// Re-renders all the compoents currently visible on screen.
  /// Call this method whenever the collecrion view changes its bounds/size.
  public func updateVisibleComponents() {
    visibleCells
      .flatMap { cell in cell as? ComponentCellType }
      .forEach { cell in cell.update(options: []) }
  }
}

