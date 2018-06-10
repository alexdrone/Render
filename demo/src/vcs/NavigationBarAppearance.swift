import UIKit
import RenderNeutrino

extension UIBaseViewController {
  func styleNavigationBar() {
    let title = string(fromType: type(of: self)).replacingOccurrences(of: "ViewController", with:"")
    view.backgroundColor = S.prop.palette_primary.color
    canvasView.backgroundColor = view.backgroundColor
    navigationItem.title = title
    let vc = self
    vc.navigationController?.navigationBar.isTranslucent = true
    vc.navigationController?.navigationBar.titleTextAttributes =
      [NSAttributedStringKey.foregroundColor: S.prop.palette_white.color]
    vc.navigationController?.navigationBar.barTintColor = S.prop.palette_primaryAccent.color
    vc.navigationController?.navigationBar.tintColor = S.prop.palette_white.color
    vc.navigationController?.navigationBar.shadowImage = UIImage()
  }
}

public extension UICustomNavigationBarProtocol where Self: UIBaseViewController {
  func styleNavigationBarComponent(title: String = "None") {
    UIApplication.shared.statusBarStyle = .lightContent
    view.backgroundColor = S.prop.palette_primary.color
    canvasView.backgroundColor = view.backgroundColor
    // Configure custom navigation bar.
    navigationBarManager.makeDefaultNavigationBarComponent()
    navigationBarManager.props.title = title
    navigationBarManager.props.style.backgroundColor = S.prop.palette_primary.color
    navigationBarManager.props.style.tintColor = S.prop.palette_accentText.color
    navigationBarManager.props.style.titleColor = S.prop.palette_white.color
  }
}
