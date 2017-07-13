import Render
import UIKit

struct CollectionNodeExampleState: StateType {
  var indexBeingDeleted: [Int] = []
  var items = Array(0..<32)
  var colors: [Int: UIColor] = [:]
  init() {
    for idx in items {
      colors[idx] = Color.darkerRed.withAlphaComponent(CGFloat.random())
    }
  }
}

class CollectionNodeExampleComponentView: ComponentView<CollectionNodeExampleState> {

  override func render() -> NodeType {

    func cellSize(size: CGSize, idx: Int) -> (CGFloat, CGFloat) {
      let width = UIScreen.main.bounds.width
      return (width/2, width/2)
    }

    // The main wrapper view (another pure function).
    func Cell(idx: Int) -> NodeType {

      let spinner = Node<UIActivityIndicatorView> { view, layout, size in
        layout.alignSelf = .center
        view.startAnimating()
      }

      let isBeingDeleted = self.state.indexBeingDeleted.contains(idx)

      // Is important that every item in the list has his own unique key.
      // Keys should be given to the elements inside the array to give the
      // elements a stable identity.
      let cell = Node<UILabel>(key: "cell_\(idx)") { [weak self] view, layout, size in
        (layout.width, layout.height) = cellSize(size: size, idx: idx)
        layout.justifyContent = .center
        view.backgroundColor = self?.state.colors[idx] ?? Color.black
        view.text = "\(idx)"
        view.textAlignment = .center
        view.font = Typography.smallBold
        view.textColor = isBeingDeleted ? Color.white.withAlphaComponent(0.2) : Color.white
        view.isUserInteractionEnabled = !isBeingDeleted
        view.onTap { [weak self] _ in self?.remove(at: idx) }
      }
      if isBeingDeleted {
        cell.add(child: spinner)
      }
      return cell
    }

    let cells = state.items.map { idx in  Cell(idx: idx) }

    let collectionView = CollectionNode(key: "colors", in: self) { view, layout, size in
      view.backgroundColor = Color.black
      layout.width = size.width
      layout.height = size.height - 64
    }.add(children: cells)


    // The table wrapper.
    let container = Node<UIView> { view, layout, size in
      layout.width = size.width
      layout.height = size.height
      layout.paddingTop = 64
    }.add(child: collectionView)

    return container
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

class CollectionNodeExampleViewController: ViewController, ComponentController {

  // Our root component.
  var component = CollectionNodeExampleComponentView()

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

