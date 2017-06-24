import Foundation
import UIKit

// MARK: - Cell protocol

public protocol ComponentCellType {

  /// Sets the component state.
  func set(state: Render.StateType, options: [RenderOption])

  /// Calls render on the underlying component view. See: 'render(in:options)' in ComponentView.
  func update(options: [RenderOption])
}

// MARK: - UITableViewCell

/// Wraps a component in a UITableViewCell.
open class ComponentTableViewCell: UITableViewCell, ComponentCellType, ComponentViewDelegate  {

  /// Sets the component state.
  public func set(state: Render.StateType, options: [RenderOption] = []) {
    componentView?.set(state: state, options: options)
  }

  public private(set) var componentView: AnyComponentView?

  public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  /// Mount the component passed as argument in the cell.
  open func mountComponentIfNecessary(forceMount: Bool = false,
                                      _ component: @autoclosure () -> AnyComponentView) {
    guard componentView == nil || forceMount else {
      return
    }
    componentView = component()
    componentView?.delegate = self
    if let componentView = componentView as? UIView {
      contentView.addSubview(componentView)
    }
    componentView?.size = { [weak self] in
      let width = self?.bounds.size.width ?? UIScreen.main.bounds.size.width
      let height: CGFloat = CGFloat.max
      return CGSize(width: width, height: height)
    }
    clipsToBounds = true
  }

  open func update(options: [RenderOption] = []) {
    selectionStyle = .none
    componentView?.update(options: options)
  }

  public func componentDidRender(_ component: AnyComponentView) {
    if let componentView = componentView as? UIView {
      contentView.frame.size = componentView.frame.size
      componentView.center = contentView.center
    }
  }

  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    return componentView?.sizeThatFits(size) ?? CGSize.zero
  }

  open override var intrinsicContentSize: CGSize {
    return componentView?.intrinsicContentSize ?? CGSize.zero
  }
}

// MARK: - UICollectionViewCell

/// Wraps a component in a UICollectionViewCell.
open class ComponentCollectionViewCell<C : ComponentViewType>: UICollectionViewCell,
                                                               ComponentCellType {

  /// Sets the component state.
  public func set(state: Render.StateType,
                  options: [RenderOption] = []) {
    componentView?.set(state: state, options: options)
  }

  public private(set) var componentView: C?

  open func mountComponentIfNecessary(_ component: @autoclosure () -> C) {
    guard componentView == nil else {
      return
    }
    componentView = component()
    if let componentView = componentView as? UIView {
      contentView.addSubview(componentView)
    }
    componentView?.size = { [weak self] in
      let width = self?.bounds.size.width ?? CGFloat.max
      let height = CGFloat.max
      return CGSize(width: width, height: height)
    }
    clipsToBounds = true
  }

  open func update(options: [RenderOption] = []) {
    componentView?.update(options: options)
    if let componentView = componentView as? UIView {
      contentView.frame.size = componentView.frame.size
    }
  }

  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    return componentView?.sizeThatFits(size) ?? CGSize.zero
  }

  open override var intrinsicContentSize: CGSize {
    return componentView?.intrinsicContentSize ?? CGSize.zero
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

