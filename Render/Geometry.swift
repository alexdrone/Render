//
//  Geometry.swift
//  Render
//
//  Created by Alex Usbergo on 28/03/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

extension Node {
    
    /// Apply the layout to the given view hierarchy.
    internal func apply(view: UIView) {
        
        let x = layout.position.left.isNormal ? CGFloat(layout.position.left) : 0
        let y = layout.position.top.isNormal ? CGFloat(layout.position.top) : 0
        let w = layout.dimension.width.isNormal ? CGFloat(layout.dimension.width) : 0
        let h = layout.dimension.height.isNormal ? CGFloat(layout.dimension.height) : 0
        
        let frame = CGRect(x: x, y: y, width: w, height: h)
        view.applyFrame(CGRectIntegral(frame))
        
        if let children = self.children {
            for (s, node) in Zip2Sequence(view.subviews, children ?? [Node]()) {
                let subview = s as UIView
                node.apply(subview)
            }
        }
    }
}

public extension CGSize {
    
    /// Undefined size
    public static let undefined = CGSize(width: CGFloat(Undefined), height: CGFloat(Undefined))
    
    /// Convenience constructor
    public init(_ width: CGFloat,_ height: CGFloat = CGFloat(Undefined)) {
        self.init(width: width, height: height)
    }
    
    /// Returns true is this value is less than .19209290E-07F
    public var isZero: Bool {
        return self.width < CGFloat(FLT_EPSILON) && self.height < CGFloat(FLT_EPSILON)
    }
}

prefix operator ~ {}

public prefix func ~(number: CGFloat) -> Float {
    return Float(number)
}

public prefix func ~(size: CGSize) -> Dimension {
    return (width: ~size.width, height: ~size.height)
}

public prefix func ~(insets: UIEdgeInsets) -> Inset {
    return (left: ~insets.left, top: ~insets.top, right: ~insets.right, bottom: ~insets.bottom, start: ~insets.left, end: ~insets.right)
}

extension Float {
    internal var isDefined: Bool {
        return self > 0 && self < 4096
    }
}

internal func zeroIfNan(value: Float) -> CGFloat {
    return value.isDefined ? CGFloat(value) : 0
}

internal func zeroIfNan(value: CGFloat) -> CGFloat {
    return Float(value).isDefined ? value : 0
}

internal func maxIfNaN(value: Float) -> CGFloat {
    return value.isDefined ? CGFloat(value) : CGFloat(FLT_MAX)
}

internal func sizeZeroIfNan(size: Dimension) -> CGSize {
    return CGSize(width: CGFloat(zeroIfNan(size.0)), height: CGFloat(zeroIfNan(size.1)))
}

internal func sizeZeroIfNan(size: CGSize) -> CGSize {
    return CGSize(width: CGFloat(zeroIfNan(size.width)), height: CGFloat(zeroIfNan(size.height)))
}

internal func sizeMaxIfNan(size: Dimension) -> CGSize {
    return CGSize(width: CGFloat(maxIfNaN(size.0)), height: CGFloat(maxIfNaN(size.1)))
}

private extension UIView {
    
    private func applyFrame(frame: CGRect) {
        
        // There's an ongoing animation
        if self.internalStore.notAnimatable && self.layer.animationKeys()?.count > 0 {

            self.internalStore.notAnimatable = false
            
            // Get the duration of the ongoing animation
            let duration = self.layer.animationKeys()?.map({ return self.layer.animationForKey($0)?.duration }).reduce(0.0, combine: { return max($0, Double($1 ?? 0.0))}) ?? 0
            
            self.alpha = 0;
            self.frame = frame
            
            // TOFIX: workaround for views that are flagged as notAnimatable
            // Set the alpha back to 1 in the next runloop
            // - Note: Currently only volatile components are the one that are flagged as not animatable
            UIView.animateWithDuration(duration, delay: duration, options: [], animations: { self.alpha = 1 }, completion: nil)
            
            // Not animated
        } else {
            self.frame = frame
        }
    }
}


