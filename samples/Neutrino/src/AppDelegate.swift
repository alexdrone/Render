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
    let vc = self
    vc.navigationController?.navigationBar.isTranslucent = true
    vc.navigationController?.navigationBar.titleTextAttributes =
      [NSAttributedStringKey.foregroundColor: context.stylesheet.palette(Palette.white)]
    vc.navigationController?.navigationBar.barTintColor =
      context.stylesheet.palette(Palette.navigationBar)
    vc.navigationController?.navigationBar.tintColor =
      context.stylesheet.palette(Palette.navigationBar)
    vc.navigationController?.navigationBar.shadowImage = UIImage()
  }
}
