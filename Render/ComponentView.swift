//
//  ComponentView.swift
//  Render
//
//  Created by Alex Usbergo on 12/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

public protocol ComponentStateType { }

/// This class define a view fragment as a composition of 'ComponentType' objects.
public class ComponentView: UIView {
    
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
    /// - Note: USe this when you wish to use this component inside another component tree.
    public var root: ComponentType?
    
    /// Constructs the component tree.
    /// - Note: Must be overriden by subclasses.
    public func construct() -> ComponentType {
        return Component<UIView>()
    }
    
    /// Render the component.
    /// - parameter size: The bounding box for this component. The default will determine the intrinsic content
    /// size for this component.
    /// - parameter state: The (optional) state for this component.
    public func render(size: CGSize = CGSize.undefined, state: ComponentStateType? = nil) {
    
        self.state = state
        if let closure = self.stateFetchClosure where self.state == nil {
            self.state = closure()
        }
        
        self.root?.render(size)
        
        let startTime = CFAbsoluteTimeGetCurrent()

        defer {
            self.updateViewHierarchy(size)
            
            let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime)*1000

            // - Note: 60fps means you need to render a frame every ~16ms to not drop any frames.
            // This is even more important when used inside a cell.
            if timeElapsed > 16 {
                print(String(format: "- warning: render (%2f) ms.", arguments: [timeElapsed]))
            }
        }
        
        // the view never rendered
        guard let old = self.root where old.renderedView != nil else {
            self.root = self.construct()
            return
        }
    
        var new = self.construct()
        
        //diff between new and old
        func diff(old: ComponentType, new: ComponentType) -> ComponentType {
            
            if old.reuseIdentifier != new.reuseIdentifier {
                return new
            }
        
            var children = [ComponentType]()
            for (o,n) in Zip2Sequence(old.children, new.children) {
                children.append(diff(o, new: n))
            }
            
            //adds the new one
            if new.children.count > old.children.count {
                for i in old.children.count..<new.children.count {
                    children.append(new.children[i])
                }
            }
            
            new.children = children
            new.renderedView = old.renderedView
            new.reset()
            return new
        }
        
        /// The resulting tree
        self.root = diff(old, new: new)
        
        if let frame = self.root?.renderedView?.frame {
            self.frame.size = frame.size
            self.root?.renderedView?.center = self.center
        }
    }
    
    /// Updates the view hierarchy in order to reflect the new component structures.
    /// The views that are no longer related to a component are pruned from the tree.
    /// The components that don't have an associated rendered view will build their views and 
    /// add it to the hierarchy.
    /// - Note: The pruned views could be inserted in a reuse pool.
    /// - parameter size: The bounding size for this render phase.
    private func updateViewHierarchy(size: CGSize = CGSize.undefined) {
        
        guard let tree = self.root else { return }
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
        
        tree.buildView()
        visit(tree, index: 0, parent: nil)
        prune(tree.renderedView!)
        mount(tree, parent: self)
        
        self.addSubview(tree.renderedView!)
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
