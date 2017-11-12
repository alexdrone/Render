import UIKit
import RenderNeutrino

class IndexViewController: UIComponentViewController<UI.Components.IndexTable> {

  override func buildRootComponent() -> UI.Components.IndexTable {
    let props = UI.Props.IndexTable()
    props.titles = [
      UI.Props.IndexCell(title: "Pure Components") { print("a") }
    ]
    return context.component(UI.Components.IndexTable.self, key: rootKey, props: props)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.title = "INDEX"
    styleNavigationBar()
  }
}
