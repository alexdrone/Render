import UIKit
import RenderInspector
import RenderNeutrino

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  func application(_ application: UIApplication, didFinishLaunchingWithOptions
                   launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Starts the inspector in debug mode.
//    #if DEBUG
//    startRenderInspectorServer()
//    #endif
    // Parse the stylesheet file.
    do {
      try UIStylesheetManager.default.load(file: "stylesheet")
    } catch {
      fatalError("Unable to find stylesheet file.")
    }
    // FPS counter.
    FPSCounter.showInStatusBar(UIApplication.shared)

    // Override point for customization after application launch.
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = UINavigationController(rootViewController: IndexViewController())
    window?.makeKeyAndVisible()
    return true
  }
}
