//
//  Component.swift
//  Render
//
//  Created by Alex Usbergo on 05/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

public protocol ComponentType: class {
    
    /// The underlying view rendered from the component.
    var renderedView: UIView? { get set }
    
    /// The unique identifier of this node is its hierarchy.
    var reuseIdentifier: String { get }

    /// The subnodes of this node.
    var children: [ComponentType] { get set }

    /// Wether the component is part of the view hierarchy or not.
    var mounted: Bool { get }
    
    /// This component is the n-th children.
    var index: Int { get set }
    
    /// Render the component.
    func render(bounds: CGSize)
    
    /// Resets the node.
    func reset()
    
    /// Force the component to construct the view.
    func buildView()
}

public class Component<ViewType: UIView>: ComponentType {

    /// The underlying view rendered from the component.
    public var view: ViewType?
    public var renderedView: UIView? {
        get { return self.view }
        set { self.view = newValue as? ViewType }
    }
    
    /// Wether the rendered view for this component is now part of the view hierarchy or not
    public var mounted: Bool {
        return self.view?.superview != nil
    }
    
    /// The view index in the view hierarchy.
    public var index: Int = 0

    /// This is crucial for ensuring proper view reuse
    /// When the reuse identifier is not explicitely set, it will be automatically set to the 'ViewType'
    /// for this component.
    public let reuseIdentifier: String
    
    /// If this is set to 'true', 'prepareForComponentReuse' is going to be called on
    /// the view associated to this component before being re-configured.
    public let prepareForReuse: Bool
    
    /// The current children for this component.
    public var children = [ComponentType]() {
        didSet {
            self.children = children.filter({ return !($0 is NilComponent) })
        }
    }
    
    /// The view initialisation closure.
    private let viewInitClosure: ((Void) -> ViewType)
    
    /// The view configuration closure.
    private var viewConfigureClosure: (ViewType) -> Void
    
    /// Creates a new component with the given view's initialization closure
    /// - parameter reuseIdentifier: A reuse identifier for this node. If nothing is passed as argument the 
    /// reuse identifier will be the component 'ViewType'.
    /// - parameter prepareForReuse: When this argument is 'true' the underlying view is reset to the original default
    /// values before being configured at every call of 'render'. Default is 'false'.
    /// - parameter initClosure: Pass this closure if you have a custom init method (or factory method) you wish to call 
    /// to initialise this view. The default is 'ViewType(frame: CGRect.zero)'
    public init(reuseIdentifier: String = String(ViewType), prepareForReuse: Bool = false, initClosure: ((Void) -> ViewType) = { return ViewType(frame: CGRect.zero) }) {
        self.prepareForReuse = prepareForReuse
        self.reuseIdentifier = reuseIdentifier
        self.viewInitClosure = initClosure
        self.viewConfigureClosure = { (_) in }
    }
    
    /// Adds a configuration closure for this component.
    /// This is going to be executed every time the component's render function is called.
    /// - parameter configurationClosure: The configuration block that will be stored and executed at every call of render.
    public func configure(configurationClosure: (ViewType) -> Void) -> Self {
        self.viewConfigureClosure = configurationClosure
        return self
    }
    
    /// Render this component recursively.
    /// - parameter bounds: The bounding box for this component. 
    /// Use 'CGSize.udefined' in order to use the component's intrinsic size.
    public func render(bounds: CGSize) {
        self.buildView()
        self.renderedView?.render(bounds)
    }
    
    /// Force the component to construct the view.
    public func buildView() {        
        if let _ = self.view { return }
        self.view = self.viewInitClosure()
        self.view?.reuseIdentifier = self.reuseIdentifier
        self.view?.style.maxDimensions = (Undefined, Undefined)
        self.reset()
    }
    
    /// Write an extension for this method to specialize the prepare for reuse for this view.
    public func reset() {
        self.renderedView?.internalStore.configureClosure = { [weak self] in
            self!.viewConfigureClosure(self!.view!)
        }
        if self.prepareForReuse && self.reuseIdentifier == String(ViewType) {
            self.renderedView?.prepareForComponentReuse()
        }
    }

}

extension ComponentType {
    
    /// Sets the children of this component.
    public func children(children: [ComponentType]) -> Self {
        for c in children {
            if c is NilComponent { continue }
            self.children.append(c)
        }
        return self
    }
    
    /// Adds a child to this component.
    public func addChild(child: ComponentType) -> Self {
        if child is NilComponent { return self }
        self.children.append(child)
        return self
    }
    
    /// Runs the closure 'count' times.
    /// - parameter count: How many times the closure is going to be executed.
    /// - parameter closure: the index is passed as argument.
    public func addChildren(count: Int, closure: (Int) -> ComponentType) -> Self {
        for i in 0..<count {
            self.addChild(closure(i))
        }
        return self
    }
    
    /// Returns the components with the associated reuse identifier.
    /// - parameter identifier: The identifier passed as argument in the component's constructor
    public func componenstWithIdentifier(identifier: String) -> [ComponentType] {
        var result = [ComponentType]()
        if self.reuseIdentifier == identifier {
            result.append(self)
        }
        for child in self.children {
            result.appendContentsOf(child.componenstWithIdentifier(identifier))
        }
        return result
    }
    
    /// Returns the first component with the associated reuse identifier.
    /// - parameter identifier: The identifier passed as argument in the component's constructor
    public func componentWithIdentifier(identifier: String) -> ComponentType? {
        return self.componenstWithIdentifier(identifier).first
    }
    
    /// Returns the view with the associated identifier.
    /// - parameter identifier: The identifier passed as argument in the component's constructor
    public func viewWithIdentifier<T:UIView>(identifier: String) -> T? {
        return self.componentWithIdentifier(identifier)?.reuseIdentifier as? T
    }
}

/// Internally used to represent a nil component.
private class NilComponent: ComponentType {
    private var renderedView: UIView? = nil
    private var reuseIdentifier: String = ""
    private var children: [ComponentType] = [NilComponent]()
    private var mounted: Bool = false
    private var index: Int = 0
    private func render(bounds: CGSize) { }
    private func reset() { }
    private func buildView() { }
}

public func when(@autoclosure condition: () -> Bool, _ component: ComponentType) -> ComponentType {
    return condition() ? component: NilComponent()
}
 