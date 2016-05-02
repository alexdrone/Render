//
//  Component.swift
//  Render
//
//  Created by Alex Usbergo on 02/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

public protocol ComponentStateType { }

public protocol Component: class {
    
    init()
    
    /// Applies the component configuration (as per ViewType extension)
    func configure(closure: ((Self) -> Void))
    
    /// The state of this component.
    var state: ComponentStateType? { get set }
    
    /// The parent for this component.
    var parentView: UIView? { get set }
    
    /// Render the component.
    /// - parameter size: The bounding box for this component. The default will determine the intrinsic content
    /// size for this component.
    /// - parameter state: The (optional) state for this component.
    func renderComponent(size: CGSize)
}