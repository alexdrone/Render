import UIKit
import Render

class Example5ViewController: ViewController, ComponentController {

  var component = PercentComponentView()

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

