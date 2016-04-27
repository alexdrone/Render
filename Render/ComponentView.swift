//
//  ComponentView.swift
//  Render
//
//  Created by Alex Usbergo on 12/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

/// This class define a view fragment as a composition of 'ComponentType' objects.
public class ComponentView: AbstractComponentView {

    public init() {
        super.init(frame: CGRect.zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Render the component.
    /// - parameter size: The bounding box for this component. The default will determine the intrinsic content
    /// size for this component.
    /// - parameter state: The (optional) state for this component.
    public override func renderComponent(size: CGSize = CGSize.undefined) {
        
        // runs its own configuration
        self.internalStore.configureClosure?()
        
        self._root?.render(size)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            self.updateViewHierarchy(size)
            debugRenderTime("\(self.dynamicType).renderComponent", startTime: startTime)
        }
        
        // the view never rendered
        guard let old = self._root where old.renderedView != nil else {
            self._root = self.construct()
            return
        }
    
        var new = self.construct()
        
        //diff between new and old
        func diff(old: ComponentType, new: ComponentType) -> ComponentType {
            
            old.prepareForUnmount()
            
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
            new.prepareForMount()
            return new
        }
        
        /// The resulting tree
        self._root = diff(old, new: new)
        
        if let frame = self._root?.renderedView?.frame {
            self.frame.size = frame.size
            self._root?.renderedView?.center = self.center
        }
    }

}

/// This class define a view fragment as a composition of 'ComponentType' objects.
/// - Note: 'StaticComponentView', opposed to 'ComponentView', calls construct() just at init time.
/// This component class has a more performant 'renderComponent' method since it doesn't update the
/// view hierarchy - hence it is reccomended for components whose view hierarchy is static (but the
/// view configuration/view layout is not).
public class StaticComponentView: AbstractComponentView {

    public init() {
        super.init(frame: CGRect.zero)
        self.commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        // construct the component view
        self._root = self.construct()
        self.updateViewHierarchy()
        
        if let frame = self._root?.renderedView?.frame {
            self.frame.size = frame.size
            self._root?.renderedView?.center = self.center
        }
    }
    
    /// Render the component.
    /// - parameter size: The bounding box for this component. The default will determine the intrinsic content
    /// size for this component.
    /// - parameter state: The (optional) state for this component.
    public override func renderComponent(size: CGSize = CGSize.undefined) {
        
        // runs its own configuration
        self.internalStore.configureClosure?()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            debugRenderTime("\(self.dynamicType).renderComponent", startTime: startTime)
        }
        
        self._root?.render(size)
        self.frame.size = self.root.renderedView!.bounds.size
    }
    
}

