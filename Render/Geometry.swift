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
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


public extension CGSize {

  /// Undefined size.
  public static let undefined = CGSize(width: CGFloat(Undefined), height: CGFloat(Undefined))

  public static func sizeConstraintToHeight(_ height: CGFloat) -> CGSize {
    return CGSize(width: CGFloat(Undefined), height: height)
  }

  public static func sizeConstraintToWidth(_ width: CGFloat) -> CGSize {
    return CGSize(width: width, height: CGFloat(Undefined))
  }

  /// Returns true is this value is less than .19209290E-07F
  public var isZero: Bool {
    return self.width < CGFloat(FLT_EPSILON) && self.height < CGFloat(FLT_EPSILON)
  }
}

public extension Float {
  public var isDefined: Bool {
    return self > 0 && self < 4096
  }
}

public extension CGFloat {
  public var isDefined: Bool {
    return Float(self).isDefined
  }
}


prefix operator ~

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
  return (left: ~insets.left,
          top: ~insets.top,
          right: ~insets.right,
          bottom: ~insets.bottom,
          start: ~insets.left,
          end: ~insets.right)
}

extension Node {

  /// Recursively apply the layout to the given view hierarchy.
  /// - parameter view: The root of the view hierarchy
  func apply(_ view: UIView) {

    let x = layout.position.left.isNormal ? CGFloat(layout.position.left) : 0
    let y = layout.position.top.isNormal ? CGFloat(layout.position.top) : 0
    let w = layout.dimension.width.isNormal ? CGFloat(layout.dimension.width) : 0
    let h = layout.dimension.height.isNormal ? CGFloat(layout.dimension.height) : 0

    let frame = CGRect(x: x, y: y, width: w, height: h)
    view.applyFrame(frame.integral)

    if let children = self.children {
      for (s, node) in zip(view.subviews, children) {
        let subview = s as UIView
        node.apply(subview)
      }
    }
  }
}

extension UIView {

  /// Set the view frame to the one passed as argument.
  /// - Note: If the view is marked as notAnimatable (likely to be a newly inserted view)
  /// any animation for this view will be suppressed.
  func applyFrame(_ frame: CGRect) {

    // There's an ongoing animation
    if self.internalStore.notAnimatable && self.layer.animationKeys()?.count > 0 {

      self.internalStore.notAnimatable = false

      // Get the duration of the ongoing animation
      let duration = self.layer.animationKeys()?.map({
        return self.layer.animation(forKey: $0)?.duration
      }).reduce(0.0, {
        return max($0, Double($1 ?? 0.0))
      }) ?? 0

      self.alpha = 0;
      self.frame = frame

      // fades in the non-animatable views.
      UIView.animate(withDuration: duration,
                                 delay: duration,
                                 options: [],
                                 animations: { self.alpha = 1 },
                                 completion: nil)
      // Not animated
    } else {
      self.frame = frame
    }
  }
}

func zeroIfNan(_ value: Float) -> CGFloat {
  return value.isDefined ? CGFloat(value) : 0
}

func zeroIfNan(_ value: CGFloat) -> CGFloat {
  return Float(value).isDefined ? value : 0
}

func maxIfNaN(_ value: Float) -> CGFloat {
  return value.isDefined ? CGFloat(value) : CGFloat(FLT_MAX)
}

func sizeZeroIfNan(_ size: Dimension) -> CGSize {
  return CGSize(width: CGFloat(zeroIfNan(size.0)), height: CGFloat(zeroIfNan(size.1)))
}

func sizeZeroIfNan(_ size: CGSize) -> CGSize {
  return CGSize(width: CGFloat(zeroIfNan(size.width)), height: CGFloat(zeroIfNan(size.height)))
}

func sizeMaxIfNan(_ size: Dimension) -> CGSize {
  return CGSize(width: CGFloat(maxIfNaN(size.0)), height: CGFloat(maxIfNaN(size.1)))
}
