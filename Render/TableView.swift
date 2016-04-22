//
//  TableView.swift
//  Render
//
//  Created by Alex Usbergo on 22/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

extension UITableView {
    
    /// Refreshes the component at the given index path.
    /// - parameter indexPath: The indexpath for the targeted component.
    /// - parameter state: (optional) replace the state of the component with the one passed as argument.
    public func renderComponentAtIndexPath(indexPath: NSIndexPath, state: ComponentStateType? = nil) {
    
        if let cell = self.cellForRowAtIndexPath(indexPath) as? ComponentCell where state != nil {
            cell.state = state
        }
        
        self.beginUpdates()
        self.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        self.endUpdates()
    }
    
    /// Re-renders all the compoents currently visible on screen.
    /// - Note: Call this method whenever the table view changes its bounds/size.
    public func renderVisibleComponents() {
        for cell in self.visibleCells {
            if let c = cell as? ComponentCell { c.renderComponent(CGSize(self.bounds.width)) }
        }
    }
    
    /// Internal store for this view of the cells.
    /// It is recommended to implement 'estimatedHeightForRowAtIndexPath' in your data-source in order to
    /// improve the performance when loading the cells.
    /// - Note: Deprecated. You can use 'UITableViewAutomaticDimension' as value for 'rowHeight'
    private var prototypes: [String: ComponentView] {
        get {
            guard let store = objc_getAssociatedObject(self, &__internalStoreHandle) as? [String: ComponentView] else {
                let store = [String: ComponentView]()
                objc_setAssociatedObject(self, &__internalStoreHandle, store, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return store
            }
            return store
        }
        set {
            objc_setAssociatedObject(self, &__internalStoreHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Register the component for the given identifier.
    /// - Note: This means that this instance will be used as prototype for calculating the height of the
    /// cells with the same reuse identifier.
    /// - Note: Deprecated. You can use 'UITableViewAutomaticDimension' as value for 'rowHeight'
    /// - parameter reuseIdentifier: The identifier that is going to be associated to the component prototype
    /// - parameter component: A component instance that is going to be used as prototype for height calculation
    public func registerPrototype(reuseIdentifier: String, component: ComponentView) {
        self.prototypes[reuseIdentifier] = component
    }
    
    /// Returns the height for the component with the given reused identifier.
    /// - Note: Make sure the method 'registerPrototype' has been called before with the desired reuse identifier.
    /// - Note: Deprecated. You can use 'UITableViewAutomaticDimension' as value for 'rowHeight'
    public func heightForCellWithState(reuseIdentifier: String, state: ComponentStateType) -> CGFloat {
        
        // no prototype
        guard let prototype = prototypes[reuseIdentifier] else {
            return 0
        }
        
        //use the prototype to calculate the height
        prototype.state = state
        prototype.renderComponent(CGSize(width: self.bounds.size.width, height: CGFloat(Undefined)))

        var size = prototype.bounds.size
        size.height += prototype.frame.origin.y + CGFloat(prototype.style.margin.top) + CGFloat(prototype.style.margin.bottom)
        let height = size.height
        
        return height
    }
}

private var __internalStoreHandle: UInt8 = 0
private var __cacheHandle: UInt8 = 0
