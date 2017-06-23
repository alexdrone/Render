import Foundation
import UIKit

// MARK: - Cell protocol

public protocol ComponentCellType {

  /// Sets the component state.
  func set(state: Render.StateType, options: [RenderOption])

  /// Calls render on the underlying component view. See: 'render(in:options)' in ComponentView.
  func update(in bounds: CGSize, options: [RenderOption])
}

// MARK: - UITableViewCell

/// Wraps a component in a UITableViewCell.
open class ComponentTableViewCell<C : ComponentViewType>: UITableViewCell, ComponentCellType {

  /// Sets the component state.
  public func set(state: Render.StateType,
                  options: [RenderOption] = [.usePreviousBoundsAndOptions]) {
    componentView?.set(state: state, options: options)
  }

  public private(set) var componentView: C?

  public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  open func mountComponentIfNecessary(_ component: @autoclosure () -> C) {
    guard componentView == nil else {
      return
    }
    componentView = component()
    if let componentView = componentView as? UIView {
      contentView.addSubview(componentView)
    }
    clipsToBounds = true
  }

  open func update(in bounds: CGSize = CGSize(width: CGFloat.undefined, height: CGFloat.max),
                   options: [RenderOption] = []) {
    var size = bounds
    size.width = size.width.isNormal ? size.width : contentView.bounds.size.width
    componentView?.update(in: size, options: options)
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

// MARK: - UICollectionViewCell

/// Wraps a component in a UICollectionViewCell.
open class ComponentCollectionViewCell<C : ComponentViewType>: UICollectionViewCell,
                                                               ComponentCellType {

  /// Sets the component state.
  public func set(state: Render.StateType,
                  options: [RenderOption] = [.usePreviousBoundsAndOptions]) {
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
    clipsToBounds = true
  }

  open func update(in bounds: CGSize = CGSize(width: CGFloat.undefined, height: CGFloat.max),
                   options: [RenderOption] = []) {
    var size = bounds
    size.width = size.width.isNormal ? size.width : contentView.bounds.size.width
    componentView?.update(in: size, options: options)
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
    let size = CGSize(width: bounds.size.width, height: CGFloat.max)
    visibleCells
      .flatMap { cell in cell as? ComponentCellType }
      .forEach { cell in cell.update(in: size, options: []) }
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
    let size = CGSize(width: bounds.size.width, height: CGFloat.max)
    visibleCells
      .flatMap { cell in cell as? ComponentCellType }
      .forEach { cell in cell.update(in: size, options: []) }
  }
}

