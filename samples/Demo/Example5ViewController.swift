import UIKit
import Render

class Example5ViewController: ViewController, ComponentController {

  var component = PercentComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    componentControllerViewDidLoad()
  }

  override func viewDidLayoutSubviews() {
    component.update(options: [])
  }
}

