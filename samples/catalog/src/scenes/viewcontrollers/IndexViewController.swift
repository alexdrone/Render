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
  }()

  /// Called after the controller's view is loaded into memory.
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = Palette.primary.color
    styleNavigationBar()
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
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    indexProps[indexPath.row].onCellSelected?()
    // We highlight the selected cell.
    for (row, prop) in indexProps.enumerated() { prop.isHighlighted = row == indexPath.row }
    reloadData()
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
}

