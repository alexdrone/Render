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
    ]
    return context.component(Index.Component.self, key: rootKey, props: props)
  }

  private func presentAppStoreEntryComponentExample() {
    navigationController?.pushViewController(AppStoreEntryViewController(), animated: true)
  }

  private func presentAppStoreListComponentExample() {
    navigationController?.pushViewController(AppStoreListViewController(), animated: true)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    styleNavigationBar()
  }
}

