import Render
import UIKit

struct TableNodeExampleState: StateType {
  var items = Array(0..<532)
}

class TableNodeExampleComponentView: ComponentView<TableNodeExampleState> {

  override func render() -> NodeType {

    // A simple component expressed as pure function.
    func RemoveButton(idx: Int) -> NodeType {
      return Node<UIButton> { view, layout, size in
        view.setTitle("Remove \(idx)", for: .normal)
        view.setTitleColor(Color.red, for: .normal)
        view.titleLabel?.font = Typography.smallBold
        view.backgroundColor = Color.black
        view.onTap { [weak self] _ in
          self?.setState { state in
            // When the button is pressed we remove the idem at the given index.
            state.items = state.items.filter { $0 != idx }
          }
        }
        layout.padding = 16
      }
    }
    // TableNode wraps a 'UITableView' and implements its children through a datasource with
    // cell reuse.
    // CollectionNode is also available ('UICollectionView' wrapper) with the same API.
    // The prop 'autoDiffEnabled' for TableNode performs a diff on the collection and execute the
    // right insertions/deletions rather then calling reloadData on the
    return TableNode(key: "cards", in: self) { view, layout, size in
      view.backgroundColor = Color.black
      layout.width = size.width
      layout.height = size.height
      layout.paddingTop = 64
      }.add(children: self.state.items.map {
        // Is important that every item in the list has his own unique key.
        // Keys should be given to the elements inside the array to give the
        // elements a stable identity.
        return Node<UIView>(key: "\($0)") { view, layout, size in
          layout.width = size.width
          layout.flexDirection = .row
        }.add(children: [
          ComponentNode(CardComponentView(), in: self, key: "card_\($0)") { component, _ in
            component.displayBlock = false
          },
          RemoveButton(idx: $0),
        ])
      })
  }
}

class TableNodeExampleViewController: ViewController, ComponentController {

  // Our root component.
  var component = TableNodeExampleComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Adds the component to the view hierarchy.
    addComponentToViewControllerHierarchy()
  }

  // Whenever the view controller changes bounds we want to re-render the component.
  override func viewDidLayoutSubviews() {
    renderComponent()
  }

  func configureComponentProps() {
    // No props to configure
  }

}

