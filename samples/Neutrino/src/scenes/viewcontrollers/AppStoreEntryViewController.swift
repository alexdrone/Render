import UIKit
import RenderNeutrino

class AppStoreEntryViewController: UIComponentViewController<UI.Components.AppStoreEntry> {

  override func buildRootComponent() -> UI.Components.AppStoreEntry {
    return context.component(UI.Components.AppStoreEntry.self,
                             key: "appstore-example",
                             props: UI.Props.AppStoreEntry.singleCardExample(),
                             parent: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = Palette.primary.color
    self.navigationItem.title = "CARD COMPONENT"
    styleNavigationBar()
  }
}
