//
//  UIView+Flexbox.swift
//  Render
//
//  Created by Alex Usbergo on 04/03/16.
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

//MARK: Layout

public protocol FlexboxView { }

extension FlexboxView where Self: UIView {
    
    /// Configure the view and its flexbox style.
    ///- Note: The configuration closure is stored away and called again in the render function
    public func configure(closure: ((Self) -> Void), children: [UIView]? = nil) -> Self {
        
        //runs the configuration closure and stores it away
        closure(self)
        self.internalStore.configureClosure = { [weak self] in
            if let _self = self {
                closure(_self)
            }
        }
        
        //adds the children as subviews
        children?.forEach(self.addSubview)

        return self
    }
    
    /// Recursively apply the configuration closure to this view tree
    private func configure() {
        func configure(view: UIView) {
            
            //runs the configure closure
            view.internalStore.configureClosure?()
            
            //calls it recursively on the subviews
            view.subviews.forEach(configure)
        }
        
        //the view is configured before the layout
        configure(self)
    }
    
    /// Re-configure the view and re-compute the flexbox layout
    public func render(bounds: CGSize = CGSize.undefined) {
        
        if self is ComponentViewType {
            print("Unable to call 'render' on a ComponentView. Please call 'renderComponent'.")
            return
        }
        
        func postRender(view: UIView) {
            view.postRender()
            view.subviews.forEach(postRender)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        self.configure()
        self.layout(bounds)
        postRender(self)

        debugRenderTime("\(self.dynamicType).render", startTime: startTime)
    }
}

extension UIView: FlexboxView {
    
    /// The style for this flexbox node
    public var style: Style { return self.flexNode.style }
    
    /// The associated reuse-identifier
    public var reuseIdentifier: String {
        get { return self.internalStore.reuseIdentifier}
        set { self.internalStore.reuseIdentifier = newValue }
    }
    
    ///Wether this view has or not a flexbox node associated
    var hasFlexNode: Bool {
        return (objc_getAssociatedObject(self, &__flexNodeHandle) != nil) 
    }
    
    /// Returns the associated node for this view.
    var flexNode: Node {
        get {
            guard let node = objc_getAssociatedObject(self, &__flexNodeHandle) as? Node else {
                
                let newNode = Node()

                newNode.measure = { (node, width, height) -> Dimension in
                    
                    if self.hidden ||  self.alpha < CGFloat(FLT_EPSILON) {
                        return (0,0) //no size for an hidden element
                    }
                    
                    self.frame = CGRect.zero
                    var size = CGSize.zero

                    size = self.sizeThatFits(CGSize(width: CGFloat(width), height: CGFloat(height)))
                    if size.isZero {
                        size = self.intrinsicContentSize()
                    }
                                        
                    var w: Float = width
                    var h: Float = height

                    if size.width > CGFloat(FLT_EPSILON) {
                        w = ~size.width
                        let lower = ~zeroIfNan(node.style.minDimensions.width)
                        let upper = ~min(maxIfNaN(width), maxIfNaN(node.style.maxDimensions.width))
                        w = w < lower ? lower : w
                        w = w > upper ? upper : w
                    }
                    
                    if size.height > CGFloat(FLT_EPSILON) {
                        h = ~size.height
                        let lower = ~zeroIfNan(node.style.minDimensions.height)
                        let upper = ~min(maxIfNaN(height), maxIfNaN(node.style.maxDimensions.height))
                        h = h < lower ? lower : h
                        h = h > upper ? upper : h
                    }
                    
                    
                    if !w.isDefined && node.style.maxDimensions.width.isDefined {
                        w = node.style.maxDimensions.width
                    }
                    if !h.isDefined && node.style.maxDimensions.height.isDefined {
                        h = node.style.maxDimensions.height
                    }
                    if !w.isDefined && node.style.minDimensions.width.isDefined {
                        w = node.style.minDimensions.width
                    }
                    if !h.isDefined && node.style.minDimensions.height.isDefined {
                        h = node.style.minDimensions.height
                    }
                    
                    return (w, h)
                }
                
                objc_setAssociatedObject(self, &__flexNodeHandle, newNode, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return newNode
            }
            
            return node
        }
        
        set {
            objc_setAssociatedObject(self, &__flexNodeHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Recursively computes the layout of this view
    private func layout(bounds: CGSize = CGSize.undefined) {

        func prepare(view: UIView) {
            for subview in view.subviews where subview.hasFlexNode {
                prepare(subview)
            }
        }
        
        prepare(self)
        
        func compute() {
            self.recursivelyAddChildren()
            self.flexNode.layout(~bounds.width, maxHeight: ~bounds.height, parentDirection: .Inherit)
            self.flexNode.apply(self)
        }
        
        compute()
    }
    
    private func recursivelyAddChildren() {
        
        //adds the children at this level
        var children = [Node]()
        for subview in self.subviews where subview.hasFlexNode {
            children.append(subview.flexNode)
        }
        self.flexNode.children = children
        
        //adds the childrens in the subiews
        for subview in self.subviews where subview.hasFlexNode {
            subview.recursivelyAddChildren()
        }
    }
}

class InternalViewStore {
    
    var configureClosure: ((Void) -> (Void))?
    
    var reuseIdentifier: String!
    
    var notAnimatable: Bool = false
}

extension UIView {
    
    /// Internal store for this view
    var internalStore: InternalViewStore {
        get {
            guard let store = objc_getAssociatedObject(self, &__internalStoreHandle) as? InternalViewStore else {
                
                //lazily creates the node
                let store = InternalViewStore()
                objc_setAssociatedObject(self, &__internalStoreHandle, store, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return store
            }
            return store
        }
    }
}

func debugRenderTime(label: String, startTime: CFAbsoluteTime, threshold: CFAbsoluteTime = 16) {
    
    let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime)*1000
    
    // - Note: 60fps means you need to render a frame every ~16ms to not drop any frames.
    // This is even more important when used inside a cell.
    if timeElapsed > threshold  {
        print(String(format: "- warning: \(label) (%2f) ms.", arguments: [timeElapsed]))
    }
}

private var __internalStoreHandle: UInt8 = 0
private var __flexNodeHandle: UInt8 = 0
