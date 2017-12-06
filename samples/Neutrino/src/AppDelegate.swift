import UIKit
import RenderInspector
import RenderNeutrino

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  func application(_ application: UIApplication, didFinishLaunchingWithOptions
                   launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    startRenderInspectorServer()

    // Override point for customization after application launch.
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = UINavigationController(rootViewController: IndexViewController())
    window?.makeKeyAndVisible()
    return true
  }
}

extension UIComponentViewController {

  func styleNavigationBar() {
    let title = string(fromType: self).replacingOccurrences(of: "ViewController", with: "")
    view.backgroundColor = Palette.primary.color
    navigationItem.title = title
    let vc = self
    vc.navigationController?.navigationBar.isTranslucent = true
    vc.navigationController?.navigationBar.titleTextAttributes =
      [NSAttributedStringKey.foregroundColor: Palette.white.color]
    vc.navigationController?.navigationBar.barTintColor = Palette.navigationBar.color
    vc.navigationController?.navigationBar.tintColor = Palette.white.color
    vc.navigationController?.navigationBar.shadowImage = UIImage()
  }
}
