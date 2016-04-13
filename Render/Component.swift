//
//  Component.swift
//  Render
//
//  Created by Alex Usbergo on 05/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

public protocol ComponentType: class {
    
    /// The underlying view rendered from the component
    var renderedView: UIView? { get set }
    
    /// The unique identifier of this node is its hierarchy
    var reuseIdentifier: String { get }

    /// The subnodes of this node
    var children: [ComponentType] { get set }

    /// Wether the component is part of the view hierarchy or not
    var mounted: Bool { get }
    
    /// This component is the n-th children
    var index: Int { get set }
    
    /// Render the component
    func render(bounds: CGSize)
    
    // Internal
    
    func reset()
    
    func buildView()
}

public class Component<ViewType: UIView>: ComponentType {

    /// The underlying view rendered from the component
    public var view: ViewType?
    public var renderedView: UIView? {
        get { return self.view }
        set { self.view = newValue as? ViewType }
    }
    
    public var mounted: Bool {
        return self.view?.superview != nil
    }
    
    public var index: Int = 0

    /// This is crucial for ensuring proper view reuse
    public let reuseIdentifier: String
    
    /// The current children for this component
    public var children = [ComponentType]()
    
    /// The view initialisation closure
    private let viewInitClosure: ((Void) -> ViewType)
    
    /// The view configuration closure
    private var viewConfigureClosure: (ViewType) -> Void
    
    /// Creates a new component with the given view's initialization closure
    public init(reuseIdentifier: String = String(ViewType), initClosure: ((Void) -> ViewType) = { return ViewType(frame: CGRect.zero) }) {
        self.reuseIdentifier = reuseIdentifier
        self.viewInitClosure = initClosure
        self.viewConfigureClosure = { (_) in }
    }
    
    /// Adds a configuration closure for this component.
    /// This is going to be executed every time the component's render function is called
    public func configure(configurationClosure: (ViewType) -> Void) -> Self {
        self.viewConfigureClosure = configurationClosure
        return self
    }
    
    public func render(bounds: CGSize) {
        self.buildView()
        self.renderedView?.render(bounds)
    }
    
    public func buildView() {
        
        if let _ = self.view { return }
        
        self.view = self.viewInitClosure()
        self.view?.reuseIdentifier = self.reuseIdentifier
        self.view?.style.maxDimensions = (Undefined, Undefined)
        self.reset()
    }
    
    public func reset() {
        self.renderedView?.internalStore.configureClosure = { [weak self] in
            self!.viewConfigureClosure(self!.view!)
        }
    }
}

extension ComponentType {
    
    /// Sets the children of this component
    public func children(children: [ComponentType]) -> Self {
        for c in children {
            self.children.append(c)
        }
        return self
    }
    
    /// Adds a child to this component
    public func addChild(child: ComponentType) -> Self {
        self.children.append(child)
        return self
    }
    
    /// Runs the closure only if the condition is satisfied
    public func when(condition: Bool, closure: (Self) -> (Void)) -> Self {
        if condition {
            closure(self)
        }
        return self
    }
    
    /// Runs the closure 'count' times
    public func each(count: Int, closure: (Self, Int) -> Void) -> Self {
        for i in 0..<count {
            closure(self, i)
        }
        return self
    }
}