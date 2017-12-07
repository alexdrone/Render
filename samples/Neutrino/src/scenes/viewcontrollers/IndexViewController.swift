import UIKit
import RenderNeutrino

class IndexViewController: UIComponentViewController<Index.Component> {

  override func buildRootComponent() -> Index.Component {
    let props = Index.Props()
    props.titles = [
      Index.CellProps(
        title: "Card Example",
        subtitle: "A complex stateful component.",
        onCellSelected: presentAppStoreEntryComponentExample),
      Index.CellProps(
        title: "Card List Example",
        subtitle: "A list of stateful components.",
        onCellSelected: presentAppStoreListComponentExample),
      Index.CellProps(
        title: "A Component with JS fragments.",
        subtitle: "And hot reload capabilities.",
        onCellSelected: presentJsCounterExample),
    ]
    return context.component(Index.Component.self, key: rootKey, props: props)
  }

  private func presentAppStoreEntryComponentExample() {
    navigationController?.pushViewController(AppStoreEntryViewController(), animated: true)
  }

  private func presentAppStoreListComponentExample() {
    navigationController?.pushViewController(AppStoreListViewController(), animated: true)
  }

  private func presentJsCounterExample() {
    navigationController?.pushViewController(JSCounterViewController(), animated: true)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    styleNavigationBar()
  }
}

