import UIKit
import Render

class Example1ViewController: ViewController, ComponentViewDelegate {

  private let component = HelloWorldComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    component.delegate = self
    view.addSubview(component)
  }

  func componentDidRender(_ component: AnyComponentView) {
    component.center = view.center
  }
}

