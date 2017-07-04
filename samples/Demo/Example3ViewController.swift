import UIKit
import Render

class Example3ViewController: ViewController, ComponentController {

  var component = ScrollableDemoComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    addComponentToViewControllerHierarchy()
  }

  override func viewDidLayoutSubviews() {
    renderComponent(options: [.preventViewHierarchyDiff])
  }

  func configureComponentProps() {
    // No props to pass down to the component.
  }
}

