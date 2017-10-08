import Render
import UIKit

class ScrollExampleComponentView: StatelessComponentView {
  override func render() -> NodeType {
    return Node<UIScrollView> { view, layout, size in
      layout.width = size.width
      layout.height = size.height
      }.add(children: Array(0..<16).map {
        ComponentNode(CardComponentView(), in: self, key: "\($0)")
      })
  }
}

class ScrollExampleViewController: ViewController, ComponentController {

  // Our root component.
  var component = ScrollExampleComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Adds the component to the view hierarchy.
    addComponentToViewControllerHierarchy()
    renderComponent()
  }

  // Whenever the view controller changes bounds we want to re-render the component.
  override func viewDidLayoutSubviews() {
    renderComponent()
  }

  func configureComponentProps() {
    // No props to configure
  }
}
