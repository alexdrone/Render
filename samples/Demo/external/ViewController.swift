import Foundation
import UIKit

class ViewController: UIViewController {

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    ViewController.styleNavigationBar(viewController: self)
    view.backgroundColor = Color.black
    title = String(describing: type(of: self)).replacingOccurrences(of: "ViewController", with: "")
  }

  static func styleNavigationBar(viewController vc: UIViewController) {
    vc.navigationController?.navigationBar.isTranslucent = false
    vc.navigationController?.navigationBar.titleTextAttributes =
      [NSForegroundColorAttributeName: Color.green]
    vc.navigationController?.navigationBar.barTintColor = Color.black
    vc.navigationController?.navigationBar.tintColor = Color.green
    vc.navigationController?.navigationBar.shadowImage = UIImage()
  }
}
