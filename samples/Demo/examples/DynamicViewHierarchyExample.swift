import Render
import UIKit

struct DynamicViewHierarchyState: StateType {
  var text: String = "Tap me"
}

// One of the most interesting features of 'Render' is that the description for your view
// hierarchy can change at every invokation of 'update' by providing a new virtual hierarchy
// in the render method.
// In this way views can truly be a pure function of their state.
class DynamicViewHierarchyComponentView: ComponentView<DynamicViewHierarchyState> {

  override func render() -> NodeType {
    let container = Node<UIView> { view, layout, size in
      view.backgroundColor = UIColor.clear
      view.onTap { [weak self] _ in
        self?.setState { state in state.text = randomString() }
      }
      layout.maxWidth = size.width - 40
      layout.flexDirection = .row
      layout.flexWrap = .wrap
      layout.flex()
    }
    let children = state.text.components(separatedBy: " ").map {
      return PaddedLabel(text: String($0))
    }
    return container.add(children: children)
  }
}

class DynamicViewHierarchyExampleViewController: ViewController, ComponentController {

  // Our root component.
  var component = DynamicViewHierarchyComponentView()

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
