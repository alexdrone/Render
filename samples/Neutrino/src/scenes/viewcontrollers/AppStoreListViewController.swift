import UIKit
import RenderNeutrino

class AppStoreListViewController: UIComponentViewController<UI.Components.AppStoreList> {

  override func buildRootComponent() -> UI.Components.AppStoreList {
    return context.component(UI.Components.AppStoreList.self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    styleNavigationBar()
  }
}

