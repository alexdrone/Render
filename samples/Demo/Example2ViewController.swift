import UIKit
import Render

class Example2ViewController: UIViewController {

  let fooComponent = FooComponentView()

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = Color.black
    self.view.addSubview(fooComponent)
    self.title = "EXAMPLE 2"
    self.generateRandomStates()
    self.fooComponent.center = self.view.center
  }

  func generateRandomStates() {
    self.fooComponent.state = FooState()
    self.fooComponent.render(in: self.view.bounds.size)
    self.fooComponent.center = self.view.center

    // Generates a new random state every 2 seconds.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      self.generateRandomStates()
    }
  }

  override func viewDidLayoutSubviews() {
    self.fooComponent.render(in: self.view.bounds.size)
    self.fooComponent.center = self.view.center
  }

}

