import Render
import UIKit

class CardComponentView: StatelessComponentView {

  var displayBlock: Bool = true
  var isGridLayout: Bool = false
  var isBeingDeleted: Bool = false

  override func render() -> NodeType {
    let shouldDisplayColumn = isGridLayout
    return Node<UIView> { [weak self] view, layout, size in
      view.backgroundColor = Color.black
      layout.padding = 8
      layout.flexDirection = shouldDisplayColumn ? .column : .row
      layout.alignSelf = .stretch
      layout.alignItems = .center
      layout.justifyContent = .center
      if self?.displayBlock ?? false {
        layout.width = size.width
      } else {
        layout.flex()
      }
      let deleted = self?.isBeingDeleted ?? false
      if deleted {
        view.alpha = 0.1
        view.isUserInteractionEnabled = false
        view.startShimmering()
      } else {
        view.isUserInteractionEnabled = true
        view.alpha = 1
        view.stopShimmering()
      }
    }.add(children: [
      // The function 'ComponentNode' is used to wrap a component inside a node.
      // When using nested component is essential to have unique keys for them.
      // A "key" is a special string attribute you need to include when creating lists of elements.
      // Keys help Render identify which items have changed, are added, or are removed.
      // Keys should be given to the elements inside the array to give the
      // elements a stable identity.
      ComponentNode(CounterComponentView(), in: self, key: "\(self.key.key)_counter"),
      ComponentNode(DynamicViewHierarchyComponentView(), in: self, key: "\(self.key.key)_desc"),
    ])
  }
}

class NestedComponentsExampleViewController: ViewController, ComponentController {

  // Our root component.
  var component = CardComponentView()

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
