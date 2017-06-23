import UIKit
import Render

class Example5ViewController: ViewController, ComponentViewDelegate {

  private let component = PercentComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(component)
    component.delegate = self
  }

  func componentDidRender(_ component: AnyComponentView) {
    component.center = self.view.center
  }
}

