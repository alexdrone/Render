import UIKit
import Render

class Example4ViewController: ViewController {

  let component = HelloWorldComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(component)
    generateRandomStates()
  }

  private func generateRandomStates() {
    component.state = HelloWorldState(name: randomString())
    component.render(in: self.view.bounds.size, options: [
      .animated(duration: 1, options: [.curveLinear]) {
        self.component.center = self.view.center
      }
    ])
    // Generates a new random state every 2 seconds.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      self?.generateRandomStates()
    }
  }

  override func viewDidLayoutSubviews() {
    component.render(in: view.bounds.size)
    component.center = view.center
  }

}

