import UIKit
import Render

class Example1ViewController: ViewController {

  private let component = HelloWorldComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(component)

    // Set a state to the component.
    component.state = HelloWorldState(name: "Alex")
  }

  override func viewDidLayoutSubviews() {
    component.render(in: view.bounds.size)
    component.center = self.view.center
  }
}

