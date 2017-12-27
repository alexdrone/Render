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
    try! UIStylesheetManager.default.load(file: "stylesheet")

    // Override point for customization after application launch.
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = UINavigationController(rootViewController: IndexViewController())
    window?.makeKeyAndVisible()
    return true
  }
}

extension UIComponentViewController {

  func styleNavigationBar() {
    let title = string(fromType: type(of: self)).replacingOccurrences(of: "ViewController", with:"")
    view.backgroundColor = Palette.primary.color
    navigationItem.title = title
    let vc = self
    vc.navigationController?.navigationBar.isTranslucent = true
    vc.navigationController?.navigationBar.titleTextAttributes =
      [NSAttributedStringKey.foregroundColor: Palette.white.color]
    vc.navigationController?.navigationBar.barTintColor = Palette.primaryAccent.color
    vc.navigationController?.navigationBar.tintColor = Palette.white.color
    vc.navigationController?.navigationBar.shadowImage = UIImage()
  }
}
