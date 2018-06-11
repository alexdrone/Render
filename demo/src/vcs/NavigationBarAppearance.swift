import UIKit
import RenderNeutrino

extension UIBaseViewController {
  func styleNavigationBar() {
    let title = string(fromType: type(of: self)).replacingOccurrences(of: "ViewController", with:"")
    view.backgroundColor = S.palette.primary.color
    canvasView.backgroundColor = view.backgroundColor
    navigationItem.title = title
    let vc = self
    vc.navigationController?.navigationBar.isTranslucent = true
    vc.navigationController?.navigationBar.titleTextAttributes =
      [NSAttributedStringKey.foregroundColor: S.palette.white.color]
    vc.navigationController?.navigationBar.barTintColor = S.palette.primaryAccent.color
    vc.navigationController?.navigationBar.tintColor = S.palette.white.color
    vc.navigationController?.navigationBar.shadowImage = UIImage()
  }
}

public extension UICustomNavigationBarProtocol where Self: UIBaseViewController {
  func styleNavigationBarComponent(title: String = "None") {
    UIApplication.shared.statusBarStyle = .lightContent
    view.backgroundColor = S.palette.primary.color
    canvasView.backgroundColor = view.backgroundColor
    // Configure custom navigation bar.
    navigationBarManager.makeDefaultNavigationBarComponent()
    navigationBarManager.props.title = title
    navigationBarManager.props.style.backgroundColor = S.palette.primary.color
    navigationBarManager.props.style.tintColor = S.palette.accentText.color
    navigationBarManager.props.style.titleColor = S.palette.white.color
  }
}
