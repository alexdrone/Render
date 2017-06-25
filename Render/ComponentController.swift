import Foundation
import UIKit

/// A lightweight wrapper controller over a component.
public protocol ComponentController: ComponentViewDelegate {

  associatedtype C: ComponentViewType

  /// The wrapped component.
  var component: C { get set }
}

public extension ComponentController where Self: UIViewController {

  // Adds the component to the view hierarchy.
 public func componentControllerViewDidLoad() {
    component.delegate = self
    if let componentView = component as? UIView {
      view.addSubview(componentView)
    }
  }

  /// By default the component is centered in the view controller main view.
  /// Overrid this method for a custom layout.
 public func componentDidRender(_ component: AnyComponentView) {
    component.center = view.center
  }
}
