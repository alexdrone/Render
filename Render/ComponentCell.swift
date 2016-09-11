//
//  ComponentCell.swift
//  Render
//
//  Created by Alex Usbergo on 21/04/16.
//
//  Copyright (c) 2016 Alex Usbergo.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

public protocol ComponentCellType {

  /// Render the component.
  /// - parameter size: The bounding box for this component. The default will determine the
  /// intrinsic content size for this component.
  /// - parameter state: The (optional) state for this component.
  func renderComponent(size: CGSize?)
}

/// Wraps a component inside a UITableViewCell.
public class ComponentTableViewCell<C: ComponentViewType>: UITableViewCell, ComponentCellType {

  /// The internal component.
  public var component: C?

  public func hasMountedComponent() -> Bool {
    return self.component != nil
  }

  public func mountComponentIfNecessary(@autoclosure component: (Void) -> C) {
    if self.component != nil {
      return
    }
    self.component = component()
    if let view = self.component as? UIView {
      self.contentView.addSubview(view)
      self.clipsToBounds = true
    }
  }

  /// Render the component.
  /// - parameter size: The bounding box for this component. The default will determine the
  /// intrinsic content size for this component.
  /// - parameter state: The (optional) state for this component.
  public func renderComponent(size: CGSize? = nil) {
    self.component?.renderComponent(size ?? self.superview?.bounds.size ?? CGSize.undefined)
    self.component?.renderComponent(size ?? self.superview?.bounds.size ?? CGSize.undefined)
    if let view = self.component as? UIView {
      self.contentView.frame = view.bounds
    }
  }

  /// Asks the view to calculate and return the size that best fits the specified size.
  /// - parameter size: The size for which the view should calculate its best-fitting size.
  /// - returns: A new size that fits the receiver’s subviews.
  public override func sizeThatFits(size: CGSize) -> CGSize {
    if let view = self.component as? UIView {
      let size = view.sizeThatFits(size)
      return size
    }
    return CGSize.zero
  }

  /// Returns the natural size for the receiving view, considering only properties of the view.
  /// - returns: A size indicating the natural size for the receiving view based on its 
  /// intrinsic properties.
  public override func intrinsicContentSize() -> CGSize {
    if let view = self.component as? UIView {
      return view.intrinsicContentSize()
    }
    return CGSize.zero
  }
}

/// Wraps a component inside a UICollectionViewCell.
public class ComponentCollectionViewCell<C: ComponentViewType>: UICollectionViewCell,
                                                                ComponentCellType {

  /// The internal component
  public var component: C?

  public func hasMountedComponent() -> Bool {
    return self.component != nil
  }

  public func mountComponentIfNecessary(component: C) {
    if self.component != nil {
      return
    }
    self.component = component
    if let view = self.component as? UIView {
      self.contentView.addSubview(view)
      self.clipsToBounds = true
    }
  }

  /// Render the component.
  /// - parameter size: The bounding box for this component. The default will determine the
  /// intrinsic content size for this component.
  /// - parameter state: The (optional) state for this component.
  public func renderComponent(size: CGSize? = nil) {
    self.component?.renderComponent(size ?? self.superview?.bounds.size ?? CGSize.undefined)

    if let view = self.component as? UIView {
      self.contentView.frame = view.bounds
    }
  }

  /// Asks the view to calculate and return the size that best fits the specified size.
  /// - parameter size: The size for which the view should calculate its best-fitting size.
  /// - returns: A new size that fits the receiver’s subviews.
  public override func sizeThatFits(size: CGSize) -> CGSize {
    self.renderComponent(size)
    if let view = self.component as? UIView {
      let size = view.sizeThatFits(size)
      return size
    }
    return CGSize.zero
  }

  /// Returns the natural size for the receiving view, considering only properties of the 
  /// view itself.
  /// - returns: A size indicating the natural size for the receiving view based on its 
  /// intrinsic properties.
  public override func intrinsicContentSize() -> CGSize {
    if let view = self.component as? UIView {
      return view.intrinsicContentSize()
    }
    return CGSize.zero
  }
}

//MARK: Extensions

extension UITableView {

  /// Refreshes the component at the given index path.
  /// - parameter indexPath: The indexpath for the targeted component.
  public func renderComponentAtIndexPath(indexPath: NSIndexPath) {
    self.beginUpdates()
    self.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    self.endUpdates()
  }

  /// Re-renders all the compoents currently visible on screen.
  /// - Note: Call this method whenever the table view changes its bounds/size.
  public func renderVisibleComponents() {
    for cell in self.visibleCells where cell is ComponentCellType {
      (cell as! ComponentCellType).renderComponent(CGSize.sizeConstraintToWidth(self.bounds.width))
    }
  }
}

extension UICollectionView {

  /// Refreshes the component at the given index path.
  /// - parameter indexPath: The indexpath for the targeted component.
  public func renderComponentAtIndexPath(indexPath: NSIndexPath) {
    self.performBatchUpdates({
      self.reloadItemsAtIndexPaths([indexPath])
      }, completion: nil)
  }

  /// Re-renders all the compoents currently visible on screen.
  /// - Note: Call this method whenever the collection view changes its bounds/size.
  public func renderVisibleComponents() {
    for cell in self.visibleCells() where cell is ComponentCellType {
      (cell as! ComponentCellType).renderComponent(CGSize.sizeConstraintToWidth(self.bounds.width))
    }
  }
}

//MARK: Prototypes

public struct ComponentPrototypes {

  /// The collection of registered prototypes.
  private static var prototypes = [String: ComponentViewType]()

  /// Register the component as a reusable component in the list component.
  /// - parameter reuseIdentifier: The identifier for this component. The default is the component 
  /// class name.
  /// - parameter component: An instance of the component.
  public static func registerComponentPrototype<C:ComponentViewType>(
      reuseIdentifier: String = String(C), component: C) {

    ComponentPrototypes.prototypes[reuseIdentifier] = component
  }

  /// Returns the size of the prototype wrapped in the view (CollectionView or TableView) 
  /// passed as argument
  public static func prototypeComponentSize(referenceView: UIView,
                                            reuseIdentifier: String,
                                            state: ComponentStateType) -> CGSize {

    guard let component = ComponentPrototypes.prototypes[reuseIdentifier] else {
      fatalError("Unregistered component with reuse identifier \(reuseIdentifier).")
    }

    // render the component.
    component.state = state
    component.referenceView = referenceView
    component.renderComponent(CGSize.sizeConstraintToWidth(referenceView.bounds.size.width))

    if let view = component as? UIView {
      return view.bounds.size
    } else {
      return CGSize.zero
    }
  }
}

