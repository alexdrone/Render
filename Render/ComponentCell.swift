import Foundation
import UIKit

// MARK: - Cell protocol

public protocol ComponentCellType {

  /** Calls render on the underlying component view. See: 'render(in:options)' in ComponentView. */
  func render(in bounds: CGSize, options: [RenderOption])
}

// MARK: - UITableViewCell

/** Wraps a 'ComponentView' in a UITableViewCell. */
open class ComponentTableViewCell<C : ComponentViewType>: UITableViewCell {

  public var state: C.StateType? {
    didSet {
      self.componentView?.state = state
    }
  }

  public private(set) var componentView: C?

  public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    self.selectionStyle = .none
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  open func mountComponentIfNecessary(_ component: @autoclosure (Void) -> C) {
    guard self.componentView == nil else {
      return
    }
    self.componentView = component()
    if let componentView = self.componentView as? UIView {
      self.contentView.addSubview(componentView)
    }
    self.clipsToBounds = true
  }

  open func render(in bounds: CGSize = CGSize(width: CGFloat.undefined, height: CGFloat.max),
                   options: [RenderOption] = []) {
    var size = bounds
    size.width = size.width.isNormal ? size.width : self.contentView.bounds.size.width
    componentView?.render(in: size, options: options)
    if let componentView = self.componentView as? UIView {
      self.contentView.frame.size = componentView.frame.size
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

/** Wraps a 'ComponentView' in a UICollectionViewCell. */
open class ComponentCollectionViewCell<C : ComponentViewType>: UICollectionViewCell {

  public var state: C.StateType?

  public private(set) var componentView: C?

  open func mountComponentIfNecessary(_ component: @autoclosure (Void) -> C) {
    guard self.componentView == nil else {
      return
    }
    self.componentView = component()
    if let componentView = self.componentView as? UIView {
      self.contentView.addSubview(componentView)
    }
    self.clipsToBounds = true
  }

  open func render(in bounds: CGSize = CGSize(width: CGFloat.undefined, height: CGFloat.max),
                   options: [RenderOption] = []) {
    var size = bounds
    size.width = size.width.isNormal ? size.width : self.contentView.bounds.size.width
    componentView?.render(in: size, options: options)
    if let componentView = self.componentView as? UIView {
      self.contentView.frame.size = componentView.frame.size
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

  /** Refreshes the component at the given index path. */
  public func render(at indexPath: IndexPath) {
    self.beginUpdates()
    self.reloadRows(at: [indexPath], with: .fade)
    self.endUpdates()
  }

  /** Re-renders all the compoents currently visible on screen.
   *  Call this method whenever the table view changes its bounds/size.
   */
  public func renderVisibleComponents() {
    let size = CGSize(width: self.bounds.size.width, height: CGFloat.max)
    self.visibleCells
      .flatMap { cell in cell as? ComponentCellType }
      .forEach { cell in cell.render(in: size, options: []) }
  }
}

extension UICollectionView {

  /** Refreshes the component at the given index path. */
  public func render(at indexPath: IndexPath) {
    self.performBatchUpdates({
      self.reloadItems(at: [indexPath])
    }, completion: nil)
  }

  /** Re-renders all the compoents currently visible on screen.
   *  Call this method whenever the collecrion view changes its bounds/size.
   */
  public func renderVisibleComponents() {
    let size = CGSize(width: self.bounds.size.width, height: CGFloat.max)
    self.visibleCells
      .flatMap { cell in cell as? ComponentCellType }
      .forEach { cell in cell.render(in: size, options: []) }
  }
}

//MARK: - Prototypes

public struct CellPrototype {

  private static var prototypes = [String: AnyComponentView]()

  public static func defaultIdentifier<C: AnyComponentView>(_ class: C.Type) -> String {
    return String(describing: C.self)
  }

  public static func register<C: AnyComponentView>(identifier: String = String(describing: C.self),
                                                   component: C) {

    CellPrototype.prototypes[identifier] = component
  }

  public static func size<C: ComponentViewType>(in container: UIView,
                                                class: C.Type,
                                                identifier: String = String(describing: C.self),
                                                state: StateType) -> CGSize {

    guard let component = CellPrototype.prototypes[identifier] as? C else {
      return CGSize.zero
    }
    component.state = state as? C.StateType

    let size = CGSize(width: container.bounds.size.width, height: CGFloat.max)
    component.render(in: size, options: [])

    guard let view = component as? UIView else {
      return CGSize.zero
    }
    return view.bounds.size
  }
}
