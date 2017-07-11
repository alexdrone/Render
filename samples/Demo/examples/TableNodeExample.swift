import Render
import UIKit

struct TableNodeExampleState: StateType {
  var indexBeingDeleted: [Int] = []
  var items = Array(0..<32)
  var useTableView = true
}

class TableNodeExampleComponentView: ComponentView<TableNodeExampleState> {

  override func render() -> NodeType {
    // Whether the cells are going to be preented using a UITableView or a UICollectionView.
    let shouldUseTableView = state.useTableView

    // A simple component expressed as pure function.
    func RemoveButton(idx: Int) -> NodeType {
      return Node<UIButton> { [weak self] view, layout, size in
        view.setTitle("DEL", for: .normal)
        view.setTitleColor(Color.white, for: .normal)
        view.titleLabel?.font = Typography.smallBold
        view.backgroundColor = Color.red
        view.isHidden = self?.state.indexBeingDeleted.contains(idx) ?? false
        view.onTap { [weak self] _ in
          self?.remove(at: idx)
        }
        layout.padding = 2
        layout.position = .absolute
        layout.alignSelf = .flexStart
        (layout.width, layout.height) = (32, 32)
        view.cornerRadius = layout.width/2
      }
    }
    // The main wrapper view (another pure function).
    func Cell(idx: Int) -> NodeType {
      // Is important that every item in the list has his own unique key.
      // Keys should be given to the elements inside the array to give the
      // elements a stable identity.
      return Node<UIView>(key: "cell_\(idx)") { view, layout, size in
        layout.width = shouldUseTableView ? size.width : size.width/2
        layout.flexDirection = .column
      }
    }
    // The table wrapper.
    let container = Node<UIView> { view, layout, size in
      layout.width = size.width
      layout.height = size.height
      layout.paddingTop = 64
    }
    let toggleListTypeButton = Node<UIButton> { view, layout, size in
      if shouldUseTableView {
        view.setTitle("Switch to UICollectionView", for: .normal)
      } else {
        view.setTitle("Switch to UITableView", for: .normal)
      }
      view.setTitleColor(Color.red, for: .normal)
      view.titleLabel?.font = Typography.smallBold
      view.onTap { [weak self] _ in
        self?.setState { state in
          state.useTableView = !state.useTableView
        }
      }
      layout.width = size.width
      layout.height = 64
    }
    // TableNode wraps a 'UITableView' and implements its children through a datasource
    // with cell reuse.
    // The prop 'autoDiffEnabled' for TableNode performs a diff on the collection and execute the
    // right insertions/deletions rather then calling reloadData on the
    let tableView = TableNode(key: "table_cards", in: self) { view, layout, size in
      view.backgroundColor = Color.black
      layout.width = size.width
      layout.height = size.height - 64
    }

    // CollectionNode wraps a 'UICollectionView' and implements its children through a datasource
    // with cell reuse.
    let collectionView = CollectionNode(key: "collection_cards", in: self) { view, layout, size in
      view.backgroundColor = Color.black
      view.debugBoudingRect()
      layout.width = size.width
      layout.flex()
    }

    let list: NodeType = shouldUseTableView ? tableView : collectionView

    let cells = state.items.map { idx in
      Cell(idx: idx).add(children: [
        // Nested components should also have a unique key otherwise it won't be
        // possible to store their state.
        // Keys are not necessary if the component is stateless.
        ComponentNode(CardComponentView(), in: self, key: "card_\(idx)") { component, _ in
          component.displayBlock = false
          component.isBeingDeleted = self.state.indexBeingDeleted.contains(idx)
          component.isGridLayout = !shouldUseTableView
        },
        RemoveButton(idx: idx),
      ])
    }

    return container.add(children: [
      toggleListTypeButton,
      list.add(children: cells)
    ])
  }

  private func remove(at idx: Int) {
    // First we mark the index for deletion.
    // 'setState' causes the component to update.
    setState(options: []) { state in
      state.indexBeingDeleted.append(idx)
    }
    // Wait for some time before removing the item from the list - simulate some sort
    // of network activity.
    let interval: TimeInterval = 2
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + interval) { [weak self] in
      // Updates the component again with the new state - the item at the given idex
      // will now be removed.
      self?.setState { state in
        state.indexBeingDeleted = state.indexBeingDeleted.filter { $0 != idx }
        // When the button is pressed we remove the idem at the given index.
        state.items = state.items.filter { $0 != idx }
      }
    }
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

