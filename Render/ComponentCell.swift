//
//  ComponentCell.swift
//  Render
//
//  Created by Alex Usbergo on 21/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

public class ComponentCell: UITableViewCell {
    
    /// The internal component
    public let component: ComponentViewType
    
    /// The state of this component.
    /// - Note: This is propagated to the associted
    public var state: ComponentStateType? {
        didSet {
            self.component.state = state
        }
    }
    
    /// Creates a new cell that will wrap the component passed as argument.
    public init(reuseIdentifier: String, component: ComponentViewType) {
        self.component = component
        super.init(style: .Default, reuseIdentifier: reuseIdentifier)
        
        if let view = self.component as? UIView {
            self.contentView.addSubview(view)
            self.clipsToBounds = true
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Render the component.
    /// - parameter size: The bounding box for this component. The default will determine the intrinsic content
    /// size for this component.
    /// - parameter state: The (optional) state for this component.
    public func renderComponent(size: CGSize? = nil) {
        self.component.renderComponent(size ?? self.superview?.bounds.size ?? CGSize.undefined)
        self.component.renderComponent(size ?? self.superview?.bounds.size ?? CGSize.undefined)
        
        if let view = self.component as? UIView {
            self.contentView.frame = view.bounds
        }
    }
    
    /// Asks the view to calculate and return the size that best fits the specified size.
    /// - parameter size: The size for which the view should calculate its best-fitting size.
    /// - returns: A new size that fits the receiver’s subviews.
    public override func sizeThatFits(size: CGSize) -> CGSize {
        
        print("self \(self) state \(state)")
        if let view = self.component as? UIView {
            let size = view.sizeThatFits(size)
            return size
        }
        return CGSize.zero
    }
    
    /// Returns the natural size for the receiving view, considering only properties of the view itself.
    /// - returns: A size indicating the natural size for the receiving view based on its intrinsic properties.
    public override func intrinsicContentSize() -> CGSize {
        if let view = self.component as? UIView {
            return view.intrinsicContentSize()
        }
        return CGSize.zero
    }
}

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
        for cell in self.visibleCells {
            if let c = cell as? ComponentCell { c.renderComponent(CGSize(self.bounds.width)) }
        }
    }
}



