import UIKit
import Render

class ComponentEmbeddedInCellExampleViewController: UITableViewController {

  private var strings: [String] = Array(0..<32).map { _ in randomString() }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    ViewController.styleNavigationBar(viewController: self)
    view.backgroundColor = Color.black
    tableView.backgroundColor = Color.black
    title = String(describing: type(of: self)).replacingOccurrences(of: "ViewController", with: "")
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 64
    tableView.separatorStyle = .none
    tableView.dataSource = self
    tableView.reloadData()
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return strings.count
  }
  
  /// Asks the data source for a cell to insert in a particular location of the table view.
  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let identifier = String(describing: ComponentTableViewCell<ComponentEmbeddedInCell>.self)

    // ComponentTableViewCell is a wrapper cell around any given component type.
    // We dequeue the cell as it is usually done.
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
      as? ComponentTableViewCell<ComponentEmbeddedInCell>
       ?? ComponentTableViewCell<ComponentEmbeddedInCell>(style: .default,
                                                         reuseIdentifier: identifier)

    // ComponentTableViewCell exposes 'configureComponent' that allows for component configuration.
    cell.configureComponent(in: tableView, indexPath: indexPath) {
      $0.text = self.strings[indexPath.row]
    }
    return cell
  }
}

class ComponentEmbeddedInCell: StatelessComponentView {

  var text: String = ""

  override func render() -> NodeType {
    return Node<UILabel> { view, layout, size in
      layout.width = size.width
      view.backgroundColor = Color.black
      view.text = self.text
      view.font = Typography.smallLight
      view.textColor = Color.white
      view.numberOfLines = 0
    }
  }
}
