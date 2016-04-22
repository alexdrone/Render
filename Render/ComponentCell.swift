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
    public let component: ComponentView
    
    /// The state of this component.
    /// - Note: This is propagated to the associted
    public var state: ComponentStateType? {
        didSet {
            self.component.state = state
        }
    }
    
    /// Creates a new cell that will wrap the component passed as argument.
    public init(reuseIdentifier: String, component: ComponentView) {
        self.component = component
        super.init(style: .Default, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(self.component)
        self.clipsToBounds = true
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
        self.contentView.frame = self.component.bounds
    }
    
    /// Asks the view to calculate and return the size that best fits the specified size.
    /// - parameter size: The size for which the view should calculate its best-fitting size.
    /// - returns: A new size that fits the receiver’s subviews.
    public override func sizeThatFits(size: CGSize) -> CGSize {
        let size = self.component.sizeThatFits(size)
        return size
    }
    
    /// Returns the natural size for the receiving view, considering only properties of the view itself.
    /// - returns: A size indicating the natural size for the receiving view based on its intrinsic properties.
    public override func intrinsicContentSize() -> CGSize {
        return self.component.intrinsicContentSize()
    }
    
}