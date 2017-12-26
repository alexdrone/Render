import UIKit
import RenderNeutrino

class IndexViewController: UIComponentViewController<Index.Component> {

  override func buildRootComponent() -> Index.Component {
    let props = Index.Props()
    props.titles = [
      Index.CellProps(
        title: "Facebook Post",
        subtitle: "A single post component.",
        onCellSelected: presentSinglePostComponentExample),
      Index.CellProps(
        title: "Facebook Feed with Table Controller",
        subtitle: """
        A list of posts implemented using a UITableComponentViewController.
        This is offer a more low-level control over some of the UITableView primitives.
        """,
        onCellSelected: presentFeedWithTableViewControllerComponentExample),
      Index.CellProps(
        title: "Facebook Feed with Table Component",
        subtitle: """
        A list of posts implemented using the UITableComponent, a component-oriented abstraction
        around UITableView.
        """,
        onCellSelected: presentFeedComponentExample),
      Index.CellProps(
        title: "Appstore-like card without Stylesheet usage.",
        subtitle: """
        A complex stateful component that doesn't rely on the stylesheet for node definitions
        """,
        onCellSelected: presentAppStoreEntryComponentExample),
      Index.CellProps(
        title: "Stylesheet-based simple Counter",
        subtitle: "A simple component that render itself using styles.",
        onCellSelected: presentStylesheetCounterExample),
    ]
    return context.component(Index.Component.self, key: rootKey, props: props)
  }

  private func presentSinglePostComponentExample() {
    navigationController?.pushViewController(SinglePostViewController(), animated: true)
  }

  private func presentFeedComponentExample() {
    navigationController?.pushViewController(FeedViewController(), animated: true)
  }

  private func presentFeedWithTableViewControllerComponentExample() {
    navigationController?.pushViewController(FeedTableViewController(), animated: true)
  }

  private func presentAppStoreEntryComponentExample() {
    navigationController?.pushViewController(AppStoreEntryViewController(), animated: true)
  }

  private func presentStylesheetCounterExample() {
    navigationController?.pushViewController(StylesheetCounterViewController(), animated: true)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    styleNavigationBar()
  }
}

