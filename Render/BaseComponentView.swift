//
//  AutolayoutComponentView.swift
//  Render
//
//  Created by Alex Usbergo on 15/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
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
            if let p = self._parentView { return p }
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

