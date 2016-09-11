//
//  ComponentViewType.swift
//  Render
//
//  Created by Alex Usbergo on 27/04/16.
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
//  FITNESS FOR A PAR wICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

extension ComponentViewType {

  /// The root node for this component.
  var root: ComponentNodeType? {
    return NilComponent()
  }

  /// The dimension of the parent
  public var referenceSize: CGSize {
    return self.referenceView?.bounds.size ?? CGSize.zero
  }
}

extension ComponentViewType where Self: FlexboxComponentView {

  /// Updates the view hierarchy in order to reflect the new component structure.
  /// The views that are no longer related to a component are pruned from the tree.
  /// The components that don't have an associated rendered view will build their views and
  /// add it to the hierarchy.
  /// - Note: The pruned views could be inserted in a reuse pool.
  /// - parameter size: The bounding size for this render phase.
  func updateViewHierarchy(_ size: CGSize = CGSize.undefined) {

    if !self.isRootInitialized { return }

    var viewSet = Set<UIView>()
    var reusedViewSet = Set<UIView>()
    let reusePool = self.reusePool

    // visits the component tree and flags the useful existing views
    func visit(_ component: ComponentNodeType, index: Int, parent: ComponentNodeType?) {
      component.index = index
      if let view = component.renderedView {
        viewSet.insert(view)
      }
      var idx = 0
      for child in component.children {
        visit(child, index: idx, parent: component)
        idx += 1
      }
    }

    // remove the views that are not necessary anymore from the hiearchy.
    func prune(_ view: UIView) {
      if !viewSet.contains(view) {
        view.removeFromSuperview()

        if InfraConfiguration.useReusePool {
          reusePool?.push(view.reuseIdentifier, view: view)
        }

      } else {
        for subview in view.subviews where subview.hasFlexNode {
          prune(subview)
        }
      }
    }

    // invoked from mount - attemps view reuse from a local shared pool.
    // - Note: Skipped when the UseReusePool configuration flag is 'false'
    func reuse(_ view: UIView?, component: ComponentNodeType) {

      guard let view = view , view.hasFlexNode else { return }

      if component.reuseIdentifier == view.reuseIdentifier {
        component.build(reusableView: view)
        reusedViewSet.insert(view)
        for (subview, subcomponent) in zip(view.subviews.filter({
          $0.hasFlexNode
        }), component.children) {
          reuse(subview, component: subcomponent)
        }
      } else {
        view.removeFromSuperview()
      }
    }

    // - Note: Skipped when .UseReusePool is 'false'
    func reuseCleanUp(_ view: UIView?) {

      guard let view = view , view.hasFlexNode else { return }

      if !reusedViewSet.contains(view) {
        view.removeFromSuperview()
      }
      for subview in view.subviews where subview.hasFlexNode {
        reuseCleanUp(subview)
      }
    }

    // recursively adds the views that are not in the hierarchy to the hierarchy.
    func mount(_ component: ComponentNodeType, parent: UIView) {

      if InfraConfiguration.useReusePool {

        // attemps view reuse from a local shared pool.
        if let reusableView = reusePool?.pop(component.reuseIdentifier) {
          reusedViewSet = Set<UIView>()
          reuse(reusableView, component: component)
          reuseCleanUp(reusableView)
        }
      }

      // mounts the view in the hierarchy.
      component.build(reusableView: nil)
      if !component.mounted {
        component.renderedView!.internalStore.notAnimatable = true
        parent.insertSubview(component.renderedView!, at: component.index)
      }
      for child in component.children {
        mount(child, parent: component.renderedView!)
      }
    }

    self.root.build(reusableView: nil)
    visit(self.root, index: 0, parent: nil)
    prune(self.root.renderedView!)
    mount(self.root, parent: self)

    self.root.render(size)
    self.updateViewFrame()
  }

  /// Updates the frame and the bounds of this (container) view
  func updateViewFrame() {

    if !self.isRootInitialized || self.root.renderedView == nil { return }

    // update the frame of this component
    self.frame.size = self.root.renderedView!.bounds.size
    let style = self.root.renderedView!.style
    self.frame.size.width += CGFloat(style.margin.left) + CGFloat(style.margin.right)
    self.frame.size.height += CGFloat(style.margin.top) + CGFloat(style.margin.bottom)
  }
}

open class FlexboxComponentView: BaseComponentView {

  /// The tree of components owned by this component view.
  var _root: ComponentNodeType?
  open var root: ComponentNodeType! {
    if _root != nil { return _root! }
    _root = construct()
    return _root!
  }

  /// 'true' is the root node has been constructed already, 'false' otherwise
  open var isRootInitialized: Bool {
    guard let _ = self._root else { return false}
    return true
  }

  /// Constructs the component tree.
  /// - Note: Must be overriden by subclasses.
  open func construct() -> ComponentNodeType {
    fatalError("unable to call 'construct' on the internal abstract class '_ComponentView'.")
  }

  /// Render the component.
  /// - parameter size: The bounding box for this component. The default will determine the
  /// intrinsic content size for this component.
  /// - parameter state: The (optional) state for this component.
  open override func renderComponent(withSize size: CGSize = CGSize.undefined) {
    fatalError("unable to call 'renderComponent' on the internal abstract class '_ComponentView'.")
  }

  /// Asks the view to calculate and return the size that best fits the specified size.
  /// - parameter size: The size for which the view should calculate its best-fitting size.
  /// - returns: A new size that fits the receiver’s subviews.
  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    self.renderComponent(withSize: size)
    return self.bounds.size
  }

  /// Returns the natural size for the receiving view, considering only properties of the view.
  /// - returns: A size indicating the natural size for the receiving view based on its
  /// intrinsic properties.
  open override var intrinsicContentSize : CGSize {
    return self.bounds.size
  }
}

/// This class define a view fragment as a composition of 'ComponentType' objects.
open class ComponentView: FlexboxComponentView {

  /// Render the component.
  /// - parameter size: The bounding box for this component. The default will determine the
  /// intrinsic content size for this component.
  /// - parameter state: The (optional) state for this component.
  open override func renderComponent(withSize size: CGSize = CGSize.undefined) {

    // runs its own configuration
    self.internalStore.configureClosure?()

    // This shouldn't be necessary since render is performed on the
    // root after the new view hiearchy is installed.
    // This could lead to a 50% perf. improvement for render.
    self._root?.render(size)

    let startTime = CFAbsoluteTimeGetCurrent()
    defer {
      self.updateViewHierarchy(size)
      debugRenderTime("\(type(of: self)).renderComponent", startTime: startTime)
    }

    // The view never rendered
    guard let old = self._root , old.renderedView != nil else {
      self._root = self.construct()
      return
    }

    var new = self.construct()

    // Diff between new and old
    func diff(_ old: ComponentNodeType, new: ComponentNodeType) -> ComponentNodeType {

      old.prepareForUnmount()

      if old.reuseIdentifier != new.reuseIdentifier {
        return new
      }

      var children = [ComponentNodeType]()
      for (o,n) in zip(old.children, new.children) {
        children.append(diff(o, new: n))
      }

      // Adds the new one
      if new.children.count > old.children.count {
        for i in old.children.count..<new.children.count {
          children.append(new.children[i])
        }
      }

      new.children = children
      new.renderedView = old.renderedView
      new.prepareForMount()
      return new
    }

    /// The resulting tree
    self._root = diff(old, new: new)
    self.updateViewFrame()
  }

}

/// This class define a view fragment as a composition of 'ComponentType' objects.
/// - Note: 'StaticComponentView', opposed to 'ComponentView', calls construct() just at init time.
/// This component class has a more performant 'renderComponent' method since it doesn't update the
/// view hierarchy - hence it is reccomended for components whose view hierarchy is static (but the
/// view configuration/view layout is not).
open class StaticComponentView: FlexboxComponentView {

  open override func initalizeComponent() {
    super.initalizeComponent()
    self._root = self.construct()
    self.updateViewHierarchy()
  }

  /// Render the component.
  /// - parameter size: The bounding box for this component. The default will determine the
  /// intrinsic content size for this component.
  /// - parameter state: The (optional) state for this component.
  open override func renderComponent(withSize size: CGSize = CGSize.undefined) {
    self.internalStore.configureClosure?()
    let startTime = CFAbsoluteTimeGetCurrent()
    defer {
      debugRenderTime("\(type(of: self)).renderComponent", startTime: startTime)
    }
    self._root?.render(size)
    self.updateViewFrame()
  }
}


