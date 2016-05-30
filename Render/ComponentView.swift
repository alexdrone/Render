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
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
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
    func updateViewHierarchy(size: CGSize = CGSize.undefined) {
        
        if !self.isRootInitialized { return }
        
        var viewSet = Set<UIView>()
        
        // visits the component tree and flags the useful existing views
        func visit(component: ComponentNodeType, index: Int, parent: ComponentNodeType?) {
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
                for subview in view.subviews where subview.hasFlexNode {
                    prune(subview)
                }
            }
        }
        
        // recursively adds the views that are not in the hierarchy to the hierarchy.
        func mount(component: ComponentNodeType, parent: UIView) {
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

public class FlexboxComponentView: BaseComponentView {

    /// The tree of components owned by this component view.
    var _root: ComponentNodeType?
    public var root: ComponentNodeType! {
        if _root != nil { return _root! }
        _root = construct()
        return _root!
    }
        
    /// 'true' is the root node has been constructed already, 'false' otherwise
    public var isRootInitialized: Bool {
        guard let _ = self._root else { return false}
        return true
    }
    
    /// Constructs the component tree.
    /// - Note: Must be overriden by subclasses.
    public func construct() -> ComponentNodeType {
        fatalError("unable to call 'construct' on the internal abstract class '_ComponentView'.")
    }
    
    /// Render the component.
    /// - parameter size: The bounding box for this component. The default will determine the intrinsic content
    /// size for this component.
    /// - parameter state: The (optional) state for this component.
    public override func renderComponent(size: CGSize = CGSize.undefined) {
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

/// This class define a view fragment as a composition of 'ComponentType' objects.
public class ComponentView: FlexboxComponentView {
    
    /// Render the component.
    /// - parameter size: The bounding box for this component. The default will determine the intrinsic content
    /// size for this component.
    /// - parameter state: The (optional) state for this component.
    public override func renderComponent(size: CGSize = CGSize.undefined) {
        
        // runs its own configuration
        self.internalStore.configureClosure?()
        
        // This shouldn't be necessary since render is performed on the
        // root after the new view hiearchy is installed.
        // This could lead to a 50% perf. improvement for render.
        self._root?.render(size)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            self.updateViewHierarchy(size)
            debugRenderTime("\(self.dynamicType).renderComponent", startTime: startTime)
        }
        
        // The view never rendered
        guard let old = self._root where old.renderedView != nil else {
            self._root = self.construct()
            return
        }

        var new = self.construct()
        
        // Diff between new and old
        func diff(old: ComponentNodeType, new: ComponentNodeType) -> ComponentNodeType {
            
            old.prepareForUnmount()
            
            if old.reuseIdentifier != new.reuseIdentifier {
                return new
            }
            
            var children = [ComponentNodeType]()
            for (o,n) in Zip2Sequence(old.children, new.children) {
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
public class StaticComponentView: FlexboxComponentView {
    
    public override func initalizeComponent() {
        super.initalizeComponent()
        self._root = self.construct()
        self.updateViewHierarchy()
    }
    
    /// Render the component.
    /// - parameter size: The bounding box for this component. The default will determine the intrinsic content
    /// size for this component.
    /// - parameter state: The (optional) state for this component.
    public override func renderComponent(size: CGSize = CGSize.undefined) {
        self.internalStore.configureClosure?()
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            debugRenderTime("\(self.dynamicType).renderComponent", startTime: startTime)
        }
        self._root?.render(size)
        self.updateViewFrame()
    }
}


