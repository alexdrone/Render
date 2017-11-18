import UIKit
import RenderNeutrino

class IndexViewController: UIComponentViewController<UI.Components.IndexTable> {

  override func buildRootComponent() -> UI.Components.IndexTable {
    let props = UI.Props.IndexTable()
    props.titles = [
      UI.Props.IndexCell(
        title: "Pure Components",
        subtitle: "A simple stateless component.") {
        print("a")
      },
      UI.Props.IndexCell(
        title: "Stateful Component",
        subtitle: "A counter that retains and changes its internal state") {
        print("a")
      },
      UI.Props.IndexCell(
        title: "Dynamic View Hierarchy",
        subtitle: "The number of children changes at every render pass.") {
        print("a")
      },
    ]
    return context.component(UI.Components.IndexTable.self, key: rootKey, props: props)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.title = "INDEX"
    styleNavigationBar()
  }
}
