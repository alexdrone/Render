import UIKit
import RenderNeutrino

class AppStoreEntryViewController: UIComponentViewController<AppStoreEntry.Component> {

  override func buildRootComponent() -> AppStoreEntry.Component {
    return context.component(AppStoreEntry.Component.self,
                             props: AppStoreEntry.Props())
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    shouldRenderAlongsideSizeTransitionAnimation = true
    styleNavigationBar()
  }
}
