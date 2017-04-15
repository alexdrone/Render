import UIKit
import Render

class Example1ViewController: UIViewController {

  let component = HelloWorldComponentView()

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = Color.black
    self.view.addSubview(component)
    self.title = "EXAMPLE 1"
    generateRandomStates()
  }

  func generateRandomStates() {
    component.state = HelloWorldState(name: "Alex")
    component.render(in: self.view.bounds.size)
    component.center = self.view.center
  }

  override func viewDidLayoutSubviews() {
    component.render(in: self.view.bounds.size)
    component.center = self.view.center
  }
}

