import UIKit
import RenderNeutrino

class AppStoreEntryViewController: UIComponentViewController<UI.Components.AppStoreEntry> {

  override func buildRootComponent() -> UI.Components.AppStoreEntry {
    return context.component(UI.Components.AppStoreEntry.self,
                             props: UI.Props.AppStoreEntry.singleCardExample())
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    styleNavigationBar()
  }
}
