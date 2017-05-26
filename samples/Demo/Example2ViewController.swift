import UIKit
import Render

class Example2ViewController: ViewController {

  private let fooComponent = FooComponentView()

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(fooComponent)
    generateRandomStates()
    fooComponent.center = view.center
  }

  private func generateRandomStates() {
    fooComponent.state = FooState()
    fooComponent.render(in: view.bounds.size, options: [

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
    fooComponent.render(in: view.bounds.size)
    fooComponent.center = view.center
  }

}

