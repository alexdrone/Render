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
  ///- Note: The configuration closure is stored away and called again in the render function.
  public func configure(_ closure: @escaping ((Self) -> Void), children: [UIView]? = nil) -> Self {

    //runs the configuration closure and stores it away.
    closure(self)
    self.internalStore.configureClosure = { [weak self] in
      if let _self = self {
        closure(_self)
      }
    }

    //adds the children as subviews.
    children?.forEach(self.addSubview)

    return self
  }

  /// Recursively apply the configuration closure to this view tree.
  fileprivate func configure() {
    func configure(_ view: UIView) {

      //runs the configure closure.
      view.internalStore.configureClosure?()

      //calls it recursively on the subviews.
      view.subviews.forEach(configure)
    }

    //the view is configured before the layout.
    configure(self)
  }

  /// Re-configure the view and re-compute the flexbox layout.
  public func render(_ bounds: CGSize = CGSize.undefined) {

    if self is ComponentViewType {
      print("Unable to call 'render' on a ComponentView. Please call 'renderComponent'.")
      return
    }

    func postRender(_ view: UIView) {
      view.postRender()
      view.subviews.forEach(postRender)
    }

    let startTime = CFAbsoluteTimeGetCurrent()

    // Reset the flexbox properties before re-render.
    if self.css_usesFlexbox {
      self.css_reset()
    }

    self.configure()
    self.layout(bounds)
    postRender(self)

    debugRenderTime("\(type(of: self)).render", startTime: startTime)
  }
}

private var __internalStoreHandle: UInt8 = 0
private var __flexNodeHandle: UInt8 = 0

extension UIView: FlexboxView {

  /// The associated reuse-identifier
  public var reuseIdentifier: String {
    get { return self.internalStore.reuseIdentifier ?? String(describing: type(of: self)) }
    set { self.internalStore.reuseIdentifier = newValue }
  }

  /// Recursively computes the layout of this view
  fileprivate func layout(_ bounds: CGSize = CGSize.undefined) {
    self.frame.size = css_sizeThatFits(bounds)
    css_applyLayout()
  }
}

class InternalViewStore {

  /// The associated view.
  private weak var view: UIView?

  init(view: UIView) {
    self.view = view
    self._closure = { [weak self] in
      self?.applyProps()
    }
  }

  /// The configuration closure for this view.
  private var _closure: ((Void) -> (Void))?
  var configureClosure: ((Void) -> (Void))? {
    set {
      _closure = { [weak self] in
        self?.applyProps()
        newValue?()
      }
    }
    get {
      return _closure
    }
  }

  /// The reuse indentifier. (The default on is the class name).
  var reuseIdentifier: String!

  /// Wheter this view can be animated or not when the diffs are applied.
  var notAnimatable: Bool = false

  /// The props for this view.
  var props: PropsType = PropsType()

  private func applyProps() {
    for (keyPath, value) in props {
      var target = value

      // Bridge to ObjC.
      if let size = value as? CGSize { target = NSValue(cgSize: size) }
      if let point = value as? CGPoint { target = NSValue(cgPoint: point) }
      if let rect = value as? CGRect { target = NSValue(cgRect: rect) }
      if let edge = value as? UIEdgeInsets { target = NSValue(uiEdgeInsets: edge) }

      self.view?.setValue(target, forKeyPath: keyPath)
    }
  }
}

extension UIView {

  /// Wether this view has or not a flexbox node associated.
  var hasNode: Bool {
    get {
      return (objc_getAssociatedObject(self, &__flexNodeHandle) as? NSNumber)?.boolValue ?? false
    }
    set {
      objc_setAssociatedObject(
        self,
        &__flexNodeHandle,
        NSNumber(value: newValue),
        objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  /// Internal store for this view.
  var internalStore: InternalViewStore {
    get {
      guard let store = objc_getAssociatedObject(self, &__internalStoreHandle)
      as? InternalViewStore else {

        // Lazily creates the node.
        let store = InternalViewStore(view: self)
        objc_setAssociatedObject(self,
                                 &__internalStoreHandle,
                                 store,
                                 objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return store
      }
      return store
    }
  }
}

func debugRenderTime(_ label: String, startTime: CFAbsoluteTime, threshold: CFAbsoluteTime = 16) {

  let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime)*1000

  // - Note: 60fps means you need to render a frame every ~16ms to not drop any frames.
  // This is even more important when used inside a cell.
  if timeElapsed > threshold  {
    print(String(format: "- warning: \(label) (%2f) ms.", arguments: [timeElapsed]))
  }
}

