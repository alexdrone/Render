//
//  ImmutableComponentView.swift
//  Render
//
//  Created by Alex Usbergo on 25/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

/// This class define a view fragment as a composition of 'ComponentType' objects.
/// - Note: 'StaticComponentView', opposed to 'ComponentView', calls construct() just at init time.
/// This component class has a more performant 'renderComponent' method since it doesn't update the 
/// view hierarchy - hence it is reccomended for components whose view hierarchy is static (but the 
/// view configuration/view layout is not).
public class StaticComponentView: UIView, ComponentViewType {
    
    /// The state of this component.
    public var state: ComponentStateType?
    private var stateFetchClosure: ((Void) -> ComponentStateType)?
    
    /// If this closure is configured, 'stateFetchClosure' is going to be executed
    /// everytime render is called for this component.
    public func withState(stateFetchClosure: (Void) -> ComponentStateType) -> Self {
        self.stateFetchClosure = stateFetchClosure
        self.state = stateFetchClosure()
        return self
    }
    
    /// The tree of components owned by this component view.
    /// - Note: Use this when you wish to use this component inside another component tree.
    private var _root: ComponentType?
    public var root: ComponentType! {
        if _root != nil { return _root! }
        _root = construct()
        return _root!
    }
    
    private let fragment: Bool
    
    /// Initialise a new component view.
    /// - parameter fragment: Set it to 'true' if this component is going to be used inside another component tree.
    public init(fragment: Bool = false) {
        self.fragment = fragment
        super.init(frame: CGRect.zero)
        
        // construct the component view
        self._root = self.construct()
        self.updateViewHierarchy()
        
        if let frame = self._root?.renderedView?.frame {
            self.frame.size = frame.size
            self._root?.renderedView?.center = self.center
        }
        
        // adds the component as subview
        if !self.fragment {
            self.addSubview(self.root.renderedView!)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Constructs the component tree.
    /// - Note: Must be overriden by subclasses.
    public func construct() -> ComponentType {
        return Component<UIView>()
    }
    
    /// Render the component.
    /// - parameter size: The bounding box for this component. The default will determine the intrinsic content
    /// size for this component.
    /// - parameter state: The (optional) state for this component.
    public func renderComponent(size: CGSize = CGSize.undefined) {
        
        if self.fragment {
            print("Render should be called on the root node.")
            return
        }
        
        if let closure = self.stateFetchClosure where self.state == nil {
            self.state = closure()
        }
        
        self._root?.render(size)
    }
    
    /// Updates the view hierarchy in order to reflect the new component structures.
    /// The views that are no longer related to a component are pruned from the tree.
    /// The components that don't have an associated rendered view will build their views and
    /// add it to the hierarchy.
    /// - Note: The pruned views could be inserted in a reuse pool.
    /// - parameter size: The bounding size for this render phase.
    private func updateViewHierarchy(size: CGSize = CGSize.undefined) {
        
        guard let tree = self._root else { return }
        
        // visits the component tree and flags the useful existing views
        func visit(component: ComponentType, index: Int, parent: ComponentType?) {
            component.index = index
            var idx = 0
            for child in component.children {
                visit(child, index: idx, parent: component)
                idx += 1
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
        
        tree.buildView()
        visit(tree, index: 0, parent: nil)
        mount(tree, parent: self)
        
        if !self.fragment {
            self.addSubview(tree.renderedView!)
        }
        tree.render(size)
    }

    /// Lays out subviews.
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    /// Asks the view to calculate and return the size that best fits the specified size.
    /// - parameter size: The size for which the view should calculate its best-fitting size.
    /// - returns: A new size that fits the receiver’s subviews.
    public override func sizeThatFits(size: CGSize) -> CGSize {
        self.render(size)
        return self.bounds.size ?? CGSize.undefined
    }
    
    /// Returns the natural size for the receiving view, considering only properties of the view itself.
    /// - returns: A size indicating the natural size for the receiving view based on its intrinsic properties.
    public override func intrinsicContentSize() -> CGSize {
        self.render(CGSize.undefined)
        return self.bounds.size ?? CGSize.undefined
    }
    
}
