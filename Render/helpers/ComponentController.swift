import Foundation
import UIKit

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
    }
    configureComponentProps()
    component.update(options: [.preventOnLayoutCallback])
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
