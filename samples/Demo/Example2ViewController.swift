import UIKit
import Render

class Example2ViewController: ViewController, ComponentViewDelegate {

  private let fooComponent = FooComponentView()

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    fooComponent.delegate = self
    view.addSubview(fooComponent)
    generateRandomStates()
  }

  private func generateRandomStates() {
    fooComponent.state = FooComponentViewState()
    fooComponent.update(in: view.bounds.size, options: [

      // Renders the component with an animation.
      .animated(duration: 0.5, options: .curveEaseInOut, alongside: {
        self.fooComponent.center = self.view.center
      })
    ])
    // Generates a new random state every 2 seconds.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
      self?.generateRandomStates()
    }
  }

  override func viewDidLayoutSubviews() {
    fooComponent.update(in: view.bounds.size)
    self.componentDidRender(fooComponent)
  }

  func componentDidRender(_ component: AnyComponentView) {
    component.center = self.view.center
  }

}

