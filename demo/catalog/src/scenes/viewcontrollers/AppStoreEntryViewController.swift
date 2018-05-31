import UIKit
import RenderNeutrino

class AppStoreEntryViewController: UIComponentViewController<AppStoreEntry.Component> {

  override func buildRootComponent() -> AppStoreEntry.Component {
    return context.component(AppStoreEntry.Component.self,
                             props: AppStoreEntry.Props())
  }

  override func viewDidLoad() {
    // Configure custom navigation bar.
    styleNavigationBarComponent(title: "Card design (No Stylesheet)")
    super.viewDidLoad()
    shouldRenderAlongsideSizeTransitionAnimation = true
  }
}
