//
//  Geometry.swift
//  Render
//
//  Created by Alex Usbergo on 28/03/16.
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

public extension CGSize {
    
    /// Undefined size.
    public static let undefined = CGSize(width: CGFloat(Undefined), height: CGFloat(Undefined))
    
    /// Convenience constructor.
    public init(_ width: CGFloat,_ height: CGFloat = CGFloat(Undefined)) {
        self.init(width: width, height: height)
    }
    
    /// Returns true is this value is less than .19209290E-07F
    public var isZero: Bool {
        return self.width < CGFloat(FLT_EPSILON) && self.height < CGFloat(FLT_EPSILON)
    }
}

prefix operator ~ {}

/// A shorthand to convert 'CGFloat' into 'Float' for flexbox.
public prefix func ~(number: CGFloat) -> Float {
    return Float(number)
}

/// A shorthand to convert 'CGSize' into 'Dimension' for flexbox.
public prefix func ~(size: CGSize) -> Dimension {
    return (width: ~size.width, height: ~size.height)
}

/// A shorthand to convert 'UIEdgeInsets' into 'Insets' for flexbox.
public prefix func ~(insets: UIEdgeInsets) -> Inset {
    return (left: ~insets.left, top: ~insets.top, right: ~insets.right, bottom: ~insets.bottom, start: ~insets.left, end: ~insets.right)
}

extension Node {
    
    /// Recursively apply the layout to the given view hierarchy.
    /// - parameter view: The root of the view hierarchy
    func apply(view: UIView) {
        
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

extension UIView {
    
    /// Set the view frame to the one passed as argument.
    /// - Note: If the view is marked as notAnimatable (likely to be a newly inserted view in the hierarchy)
    /// any animation for this view will be suppressed.
    func applyFrame(frame: CGRect) {
        
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

extension Float {
    var isDefined: Bool {
        return self > 0 && self < 4096
    }
}

func zeroIfNan(value: Float) -> CGFloat {
    return value.isDefined ? CGFloat(value) : 0
}

func zeroIfNan(value: CGFloat) -> CGFloat {
    return Float(value).isDefined ? value : 0
}

func maxIfNaN(value: Float) -> CGFloat {
    return value.isDefined ? CGFloat(value) : CGFloat(FLT_MAX)
}

func sizeZeroIfNan(size: Dimension) -> CGSize {
    return CGSize(width: CGFloat(zeroIfNan(size.0)), height: CGFloat(zeroIfNan(size.1)))
}

func sizeZeroIfNan(size: CGSize) -> CGSize {
    return CGSize(width: CGFloat(zeroIfNan(size.width)), height: CGFloat(zeroIfNan(size.height)))
}

func sizeMaxIfNan(size: Dimension) -> CGSize {
    return CGSize(width: CGFloat(maxIfNaN(size.0)), height: CGFloat(maxIfNaN(size.1)))
}
