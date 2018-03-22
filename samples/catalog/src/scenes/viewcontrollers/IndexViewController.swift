import UIKit
import RenderNeutrino

class IndexViewController: UITableComponentViewController {

  lazy var indexProps: [Index.CellProps] = {
    return [
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
        title: "Getting Started I",
        subtitle: "Simple stateless component.",
        onCellSelected: presentSimpleCounterExample1),
      Index.CellProps(
        title: "Getting Started II",
        subtitle: "A stateful counter.",
        onCellSelected: presentSimpleCounterExample2),
      Index.CellProps(
        title: "Getting Started III",
        subtitle: "A stateful counter with props externally injected.",
        onCellSelected: presentSimpleCounterExample3),
      Index.CellProps(
        title: "Getting Started IV",
        subtitle: "Introducing styles.",
        onCellSelected: presentSimpleCounterExample4),
      Index.CellProps(
        title: "Getting Started V",
        subtitle: "YAML Stylesheet and hot reload.",
        onCellSelected: presentSimpleCounterExample5),
    ]
  }()

  /// Called after the controller's view is loaded into memory.
  override func viewDidLoad() {
    styleNavigationBarComponent(title: "Index")
    super.viewDidLoad()
  }

  // MARK: UITableViewDataSource

  /// Tells the data source to return the number of rows in a given section of a table view.
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return indexProps.count
  }

  /// Asks the data source for a cell to insert in a particular location of the table view.
  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let component = context.component(Index.Cell.self,
                                      key: defaultKey(forIndexPath: indexPath),
                                      props: indexProps[indexPath.row],
                                      parent: nil)
    return dequeueCell(forComponent: component)
  }

  /// Tells the delegate that the specified row is now selected.
  @objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    indexProps[indexPath.row].onCellSelected?()
  }

  @objc func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
    // We highlight the selected cell.
    for (row, prop) in indexProps.enumerated() { prop.isHighlighted = row == indexPath.row }
    setNeedsRenderVisibleComponents()
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

  private func presentSimpleCounterExample1() {
    navigationController?.pushViewController(SimpleCounterViewController1(), animated: true)
  }

  private func presentSimpleCounterExample2() {
    navigationController?.pushViewController(SimpleCounterViewController2(), animated: true)
  }

  private func presentSimpleCounterExample3() {
    navigationController?.pushViewController(SimpleCounterViewController3(), animated: true)
  }

  private func presentSimpleCounterExample4() {
    navigationController?.pushViewController(SimpleCounterViewController4(), animated: true)
  }

  private func presentSimpleCounterExample5() {
    navigationController?.pushViewController(SimpleCounterViewController5(), animated: true)
  }
}

