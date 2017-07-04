import UIKit
import Render

class Example1ViewController: ViewController, ComponentController {
  var component = HelloWorldComponentView()

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

