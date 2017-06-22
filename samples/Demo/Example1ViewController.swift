import UIKit
import Render

class Example1ViewController: ViewController, ComponentViewDelegate {

  private let component = HelloWorldComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    component.delegate = self
    view.addSubview(component)
  }

  override func viewDidLayoutSubviews() {
    component.update(in: view.bounds.size)
    self.componentDidRender(component)
  }

  func componentDidRender(_ component: AnyComponentView) {
    component.center = self.view.center
  }
}

