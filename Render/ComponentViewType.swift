//
//  ComponentViewType.swift
//  Render
//
//  Created by Alex Usbergo on 27/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

public protocol ComponentStateType { }

public protocol ComponentViewType: class {
    
    /// The state of this component.
    var state: ComponentStateType? { get set }
    
    /// The parent for this component.
    var parentView: UIView? { get set }
    
    /// The tree of components owned by this component view.
    /// - Note: USe this when you wish to use this component inside another component tree.
    var root: ComponentType! { get }
    
    /// 'true' is the root node has been constructed already, 'false' otherwise
    var isRootInitialize: Bool { get }
    
    /// Render the component.
    /// - parameter size: The bounding box for this component. The default will determine the intrinsic content
    /// size for this component.
    /// - parameter state: The (optional) state for this component.
    func renderComponent(size: CGSize)
}

extension ComponentViewType where Self: UIView {
    
    /// The dimension of the parent
    public var parentSize: CGSize {
        return self.parentView?.bounds.size ?? CGSize.zero
    }
    
    /// Updates the view hierarchy in order to reflect the new component structures.
    /// The views that are no longer related to a component are pruned from the tree.
    /// The components that don't have an associated rendered view will build their views and
    /// add it to the hierarchy.
    /// - Note: The pruned views could be inserted in a reuse pool.
    /// - parameter size: The bounding size for this render phase.
    internal func updateViewHierarchy(size: CGSize = CGSize.undefined) {
        
        if !self.isRootInitialize { return }
        
        var viewSet = Set<UIView>()
        
        // visits the component tree and flags the useful existing views
        func visit(component: ComponentType, index: Int, parent: ComponentType?) {
            
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
        func prune(view: UIView) {
            if !viewSet.contains(view) {
                view.removeFromSuperview() //todo: put in a global reusable pool?
                
            } else {
                for subview in view.subviews.filter({ return $0.hasFlexNode }) {
                    prune(subview)
                }
            }
        }
        
        // recursively adds the views that are not in the hierarchy to the hierarchy.
        func mount(component: ComponentType, parent: UIView) {
            component.buildView()
            if !component.mounted {
                component.renderedView!.internalStore.notAnimatable = true
                parent.insertSubview(component.renderedView!, atIndex: component.index)
            }
            for child in component.children {
                mount(child, parent: component.renderedView!)
            }
        }
        
        self.root.buildView()
        visit(self.root, index: 0, parent: nil)
        prune(self.root.renderedView!)
        mount(self.root, parent: self)
        
        self.root.render(size)
        
        self.frame.size = self.root.renderedView!.bounds.size
    }
}

public class AbstractComponentView: UIView, ComponentViewType {
    
    /// The state of this component.
    public var state: ComponentStateType?
    
    /// The tree of components owned by this component view.
    internal var _root: ComponentType?
    public var root: ComponentType! {
        if _root != nil { return _root! }
        _root = construct()
        return _root!
    }
    
    /// 'true' is the root node has been constructed already, 'false' otherwise
    public var isRootInitialize: Bool {
        guard let _ = self._root else { return false}
        return true
    }
    
    /// The parent for this component
    internal weak var _parentView: UIView?
    public var parentView: UIView? {
        get {
            if let p = self._parentView { return p }
            return self.superview
        }
        set {
            self._parentView = newValue
        }
    }
    
    /// Constructs the component tree.
    /// - Note: Must be overriden by subclasses.
    public func construct() -> ComponentType {
        fatalError("unable to call 'construct' on the internal abstract class '_ComponentView'.")
    }
    
    /// Render the component.
    /// - parameter size: The bounding box for this component. The default will determine the intrinsic content
    /// size for this component.
    /// - parameter state: The (optional) state for this component.
    public func renderComponent(size: CGSize = CGSize.undefined) {
        fatalError("unable to call 'renderComponent' on the internal abstract class '_ComponentView'.")
    }
    
    /// Asks the view to calculate and return the size that best fits the specified size.
    /// - parameter size: The size for which the view should calculate its best-fitting size.
    /// - returns: A new size that fits the receiver’s subviews.
    public override func sizeThatFits(size: CGSize) -> CGSize {
        self.renderComponent(size)
        return self.bounds.size ?? CGSize.undefined
    }
    
    /// Returns the natural size for the receiving view, considering only properties of the view itself.
    /// - returns: A size indicating the natural size for the receiving view based on its intrinsic properties.
    public override func intrinsicContentSize() -> CGSize {
        return self.bounds.size ?? CGSize.undefined
    }
}
