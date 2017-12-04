import UIKit
import RenderNeutrino

class IndexViewController: UIComponentViewController<UI.Components.IndexTable> {

  override func buildRootComponent() -> UI.Components.IndexTable {
    let props = UI.Props.IndexTable()
    props.titles = [
      UI.Props.IndexCell(
        title: "Card Example",
        subtitle: "A complex stateful component.",
        onCellSelected: presentAppStoreEntryComponentExample),
      UI.Props.IndexCell(
        title: "Card List Example",
        subtitle: "A list of stateful components.",
        onCellSelected: presentAppStoreListComponentExample),
      UI.Props.IndexCell(
        title: "A Component with JS fragments.",
        subtitle: "And hot reload capabilities.",
        onCellSelected: presentJsCounterExample),
    ]
    return context.component(UI.Components.IndexTable.self, key: rootKey, props: props)
  }

  private func presentAppStoreEntryComponentExample() {
    navigationController?.pushViewController(AppStoreEntryViewController(), animated: true)
  }

  private func presentAppStoreListComponentExample() {
    navigationController?.pushViewController(AppStoreListViewController(), animated: true)
  }

  private func presentJsCounterExample() {
    navigationController?.pushViewController(JsCounterViewController(), animated: true)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.title = "NEUTRINO CATALOG"
    styleNavigationBar()
  }
}
