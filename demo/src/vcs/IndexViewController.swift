import UIKit
import RenderNeutrino

class IndexViewController: UITableComponentViewController {

  lazy var indexProps: [Index.CellProps] = {
    return [
      Index.CellProps(
        title: "Getting Started",
        subtitle: "Introduction to Render",
        onCellSelected: presentGettingStarted),
      Index.CellProps(
        title: "Facebook Post",
        subtitle: "A single post component.",
        onCellSelected: presentSinglePostComponentExample),
      Index.CellProps(
        title: "Facebook Feed with Table Controller",
        subtitle: "A list of posts implemented using UITableComponentViewController.",
        onCellSelected: presentFeedWithTableViewControllerComponentExample),
      Index.CellProps(
        title: "Custom NavigationBar",
        subtitle: "Show how to customize the component-based navigation bar.",
        onCellSelected: presentCustomNavigationBarExample),
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
      Index.CellProps(
        title: "View Controller transition demo",
        subtitle: "Transition between two scenes using components.",
        onCellSelected: presentTransitionDemo),
    ]
  }()

  override func renderCellDescriptors() -> [UIComponentCellDescriptor] {
    return indexProps.enumerated().compactMap { (index: Int, props: Index.CellProps) in
      let cmp =  context.component(Index.Cell.self, key: "\(index)", props: props, parent: nil)
      return UIComponentCellDescriptor(component: cmp)
    }
  }

  /// Called after the controller's view is loaded into memory.
  override func viewDidLoad() {
    styleNavigationBarComponent(title: "Index")
    super.viewDidLoad()
  }

  // MARK: UITableViewDataSource

  @objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    didSelectRowAt(props: indexProps, indexPath: indexPath)
  }

  @objc func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
    didHighlightRowAt(props: indexProps, indexPath: indexPath)
  }

  // MARK: Presents the other scences

  private func presentSinglePostComponentExample() {
    navigationController?.pushViewController(SinglePostViewController(), animated: true)
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

  private func presentCustomNavigationBarExample() {
    navigationController?.pushViewController(CustomNavigationBarViewController(), animated: true)
  }

  private func presentGettingStarted() {
    navigationController?.pushViewController(GettingStartedViewController(), animated: true)
  }
  private func presentTransitionDemo() {
    navigationController?.pushViewController(TransitionFromDemoViewController(), animated: true)
  }
}

