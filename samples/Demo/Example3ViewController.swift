import UIKit
import Render

class Example3ViewController: ViewController, ComponentController {

  var component = ScrollableDemoComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    componentControllerViewDidLoad()
  }

  override func viewDidLayoutSubviews() {
    component.update(options: [])
  }

}

