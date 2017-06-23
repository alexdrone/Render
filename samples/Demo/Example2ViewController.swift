import UIKit
import Render

class Example2ViewController: ViewController, ComponentViewDelegate {

  private let fooComponent = FooComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    fooComponent.delegate = self
    view.addSubview(fooComponent)
    newState()
  }

  private func newState() {
    fooComponent.set(state: FooComponentViewState(), options: [
      // Renders the component with an animation.
      .animated(duration: 0.5, options: .curveEaseInOut, alongside: nil)
    ])

    // Generates a new random state every 2 seconds.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
      self?.newState()
    }
  }

  func componentDidRender(_ component: AnyComponentView) {
    component.center = self.view.center
  }

}

