import UIKit
import Render

class Example2ViewController: ViewController, ComponentController {

  var component = FooComponentView()

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

  private func newState() {
    component.set(state: FooComponentViewState(), options: [
      // Renders the component with an animation.
      .animated(duration: 0.5, options: .curveEaseInOut)
    ])

    // Generates a new random state every 2 seconds.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
      self?.newState()
    }
  }
}

