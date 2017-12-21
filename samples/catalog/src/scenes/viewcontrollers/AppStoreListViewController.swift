import UIKit
import RenderNeutrino

class AppStoreListViewController: UIComponentViewController<AppStoreList.Component> {

  override func buildRootComponent() -> AppStoreList.Component {
    return context.component(AppStoreList.Component.self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    styleNavigationBar()
  }
}

