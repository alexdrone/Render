//
//  ComponentViewType.swift
//  Render
//
//  Created by Alex Usbergo on 02/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

public protocol ComponentStateType { }

public protocol ComponentViewType: class {
    
    init()
        
    /// Applies the component configuration (as per ViewType extension)
    /// - Note: If your view is a custom 'ComponentViewType' class (Not inheriting from BaseComponentView)
    /// then you are expected to store this closure and run it when 'renderComponent' is called.
    func configure(closure: ((ComponentViewType) -> Void))
    
    /// The state of this component.
    var state: ComponentStateType? { get set }
    
    /// The parent for this component.
    /// - Note: Although it is usually the superview, do not assume that is the same thing.
    /// Use this as reference for size calculation.
    weak var parentView: UIView? { get set }

    /// Render the component.
    /// - parameter size: The bounding box for this component. The default will determine the intrinsic content
    /// size for this component.
    /// - parameter state: The (optional) state for this component.
    func renderComponent(size: CGSize)
}
