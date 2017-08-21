import Foundation
import UIKit

//MARK: - ViewController integration helper

/// A lightweight wrapper controller over a component.
public protocol ComponentController {
  associatedtype C: ComponentViewType

  /// The wrapped component.
  var component: C { get set }

  /// Invoked before 'renderComponent'. Configure your root component properties here.
  func configureComponentProps()
}

public extension ComponentController where Self: UIViewController {

 /// Adds the component to the view hierarchy.
  public func addComponentToViewControllerHierarchy() {
    component.onLayoutCallback = { [weak self] duration, component, size in
      self?.onLayout(duration: duration, component: component, size: size)
    }
    if let componentView = component as? UIView {
      view.addSubview(componentView)
      configureComponentProps()
    }
  }

  /// Update the component.
  /// The 'configureComponentProps' callback is called before the reder pass.
  public func renderComponent(options: [RenderOption] = []) {
    configureComponentProps()
    component.update(options: options)
  }

  /// By default the component is centered in the view controller main view.
  /// Overrid this method for a custom layout.
  public func onLayout(duration: TimeInterval, component: AnyComponentView, size: CGSize) {
    component.center = view.center
  }
}

//MARK: - Autolayout integration helper

/// A simple wrapper view that allows for ComponentViews to be used in a AutoLayout managed
/// view hierarchy.
open class AutoLayoutComponentAnchorView<C: AnyComponentView>: UIView {

  /// The wrapped component view.
  public let componentView: C

  /// Initialize the view with the given component.
  public init(component: C) {
    componentView = component
    super.init(frame: CGRect.zero)
    componentView.onLayoutCallback = { [weak self] duration, component, size in
      self?.onLayout(duration: duration, component: component, size: size)
    }
    if let view = componentView as? UIView {
      addSubview(view)
    }
    isOpaque = true
    translatesAutoresizingMaskIntoConstraints = false
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    componentView.update(options: [])
  }

  open func onLayout(duration: TimeInterval, component: AnyComponentView, size: CGSize) {
    component.frame = bounds
  }
}

@IBDesignable @objc open class InspectableComponentAnchorView: UIView {

  public var componentView: AnyComponentView? {
    willSet {
      guard let view = componentView as? UIView else {
        return
      }
      view.removeFromSuperview()
    }
    didSet {
      componentView?.onLayoutCallback = { [weak self] duration, component, size in
        self?.onLayout(duration: duration, component: component, size: size)
      }
      if let view = componentView as? UIView {
        addSubview(view)
      }
      isOpaque = true
      translatesAutoresizingMaskIntoConstraints = false
      setNeedsLayout()
    }
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    componentView?.update(options: [])
  }

  open func onLayout(duration: TimeInterval, component: AnyComponentView, size: CGSize) {
    component.frame = bounds
  }
}

