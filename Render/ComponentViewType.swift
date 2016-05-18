//
//  ComponentViewType.swift
//  Render
//
//  Created by Alex Usbergo on 02/05/16.
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

/// Used mostyle as base class for internal tests.
public class ComponentStateBase: NSObject, ComponentStateType {
}
