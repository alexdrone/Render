//
//  AutolayoutComponentView.swift
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

public class BaseComponentView: UIView, ComponentViewType {
    
    public required init() {
        super.init(frame: CGRect.zero)
        self.initalizeComponent()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.initalizeComponent()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initalizeComponent()
    }
    
    /// The component initialization.
    /// - Note: Always call the super implemention.
    public func initalizeComponent() {
    }
    
    /// Applies the component configuration (as per ViewType extension)
    public func configure(closure: ((ComponentViewType) -> Void)) {
        self.internalStore.configureClosure = { [weak self] in
            if let _self = self {
                closure(_self)
            }
        }
    }
    
    /// The state of this component.
    public var state: ComponentStateType?
    
    /// The parent for this component
    internal weak var _parentView: UIView?
    public var parentView: UIView? {
        get {
            if let parent = self._parentView { return parent }
            return self.superview
        }
        set {
            self._parentView = newValue
        }
    }
    
    /// This method should be overriden by the subclass and define the component
    /// configuration for the current state.
    /// - Note: Always call the super implemention.
    public func renderComponent(size: CGSize = CGSize.undefined) {
        self.internalStore.configureClosure?()
    }
    
}

