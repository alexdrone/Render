import UIKit
import Render

class Example1ViewController: ViewController, ComponentController {

  var component = HelloWorldComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    componentControllerViewDidLoad()
  }

}

