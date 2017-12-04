import UIKit
import RenderNeutrino

class AppStoreListViewController: UIComponentViewController<UI.Components.AppStoreList> {

  override func buildRootComponent() -> UI.Components.AppStoreList {
    return context.component(UI.Components.AppStoreList.self,
                             key: "appstore-example-list",
                             props: UINilProps.nil,
                             parent: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = Palette.primary.color
    self.navigationItem.title = "CARD LIST"
    styleNavigationBar()
  }
}

