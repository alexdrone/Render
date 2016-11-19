//
//  Style.swift
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

public protocol StyleType {

  /// Applies the style to the view pased as argument.
  /// - parameter view: The target view.
  func apply(in view: UIView)
}

public func +(lhs: StyleType, rhs: StyleType) -> StyleType {
  return CompoundStyle(styles: [lhs, rhs])
}

public struct Style<ViewType: UIView>: StyleType {

  // The associated cloure that applies the style to the target view.
  public let closure: (ViewType) -> Void

  public init(closure: @escaping (ViewType) -> Void) {
    self.closure = closure
  }

  /// Applies the style to the view pased as argument.
  /// - parameter view: The target view.
  public func apply(in view: UIView) {
    if let view = view as? ViewType {
      self.closure(view)
    }
  }
}

public struct CompoundStyle: StyleType {

  /// All the styles that form the compound.
  /// - Note: The style are applied in order.
  let styles: [StyleType]

  public init(styles: [StyleType]) {
    self.styles = styles
  }

  /// Applies the style to the view pased as argument.
  /// - parameter view: The target view.
  public func apply(in view: UIView) {
    for style in self.styles {
      style.apply(in: view)
    }
  }
}

public extension UIView {

  /// Apply the component style passed as argument.
  /// - parameter style: A component style object.
  public func apply(style: StyleType) {
    style.apply(in: self)
  }
}

