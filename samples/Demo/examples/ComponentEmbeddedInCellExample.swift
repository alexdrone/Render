import UIKit
import Render

class ComponentEmbeddedInCellExampleViewController: UITableViewController {

  private var strings: [String] = Array(0..<32).map { _ in
    Array(0...randomInt(1, max: 10)).map({ _ in randomString() }).reduce("") { $0 + $1 }
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    ViewController.styleNavigationBar(viewController: self)

    view.backgroundColor = Color.black
    title = String(describing: type(of: self)).replacingOccurrences(of: "ViewController", with: "")

    tableView.withAutomaticDimension(dataSource: self)
    tableView.backgroundColor = Color.black
  }

  override func viewDidLayoutSubviews() {
    tableView.updateVisibleComponents()
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return strings.count
  }
  
  /// Asks the data source for a cell to insert in a particular location of the table view.
  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell: ComponentTableViewCell<ComponentInCell> = tableView.dequeueReusableComponentCell()

    // ComponentTableViewCell exposes 'configureComponent' that allows for component configuration.
    cell.configureComponent(in: tableView, indexPath: indexPath) {
      $0.text = self.strings[indexPath.row]
    }
    return cell
  }


}

class ComponentInCell: StatelessComponentView {

  var text: String = ""

  override func render() -> NodeType {
    let container = Node<UIView> { view, layout, size in
      layout.padding = 16
      layout.width = size.width
    }
    return container.add(child: Node<UILabel> { view, layout, size in
      view.backgroundColor = Color.black
      view.text = self.text
      view.font = Typography.smallLight
      view.textColor = Color.white
      view.numberOfLines = 0
    })
  }
}
