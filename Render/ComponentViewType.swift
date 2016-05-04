//
//  ComponentViewType.swift
//  Render
//
//  Created by Alex Usbergo on 02/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

/// The state used as input for the render function of the component.
public protocol ComponentStateType {

}

/// The design pattern in Render is analogous to React.
/// The component is a function that takes data (ComponentStateType) and returns an immutable 
/// description of views.
/// Any view that is compliant to 'ComponentViewType' must take a 'state' as input and a optional 
/// configuration closure. 
/// When 'renderComponent' is called, the component should be rendered using the 'state' as input.
/// - Note: Any view can conform to 'ComponentViewType', not only 'ComponentView' and 'StaticComponentView' subclasses.
public protocol ComponentViewType: class {
    
    init()
        
    /// Applies the component configuration (as per ViewType extension).
    /// This configuration closure is symmetrical to setting the 'props' in React.
    /// - Note: If your view is a custom 'ComponentViewType' class (Not inheriting from BaseComponentView)
    /// then you are expected to store this closure and run it when 'renderComponent' is called.
    func configure(closure: ((ComponentViewType) -> Void))
    
    /// The state of this component.
    var state: ComponentStateType? { get set }
    
    /// The parent for this component.
    /// - Note: Although it is usually the superview, do not assume that is the same thing.
    /// (For example if the component is wrapped inside a cell, the parent view will be the CollectionView).
    /// Use this as reference for size calculation.
    weak var parentView: UIView? { get set }

    /// Render the component.
    /// - parameter size: The bounding box for this component. The default will determine the intrinsic content
    /// size for this component.
    /// - parameter state: The (optional) state for this component.
    func renderComponent(size: CGSize)
}
