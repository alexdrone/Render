import UIKit
import Render

class Example4ViewController: UIViewController {

  let component = HelloWorldComponentView()

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = Color.black
    self.view.addSubview(component)
    self.title = "EXAMPLE 4"
    generateRandomStates()
  }

  func generateRandomStates() {
    component.state = HelloWorldState(name: "Animations")
    component.render(in: self.view.bounds.size, options: [
      .animated(duration: 1, options: [.curveLinear]) {
        self.component.center = self.view.center
      }
    ])
    // Generates a new random state every 2 seconds.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.generateRandomStates()
    }
  }

  override func viewDidLayoutSubviews() {
    component.render(in: self.view.bounds.size)
    self.component.center = self.view.center
  }

}

