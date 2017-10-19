import UIKit
import RenderNeutrino
import UI

class ViewController: UIViewController {

  let context = UIContext()
  var component: PaddedLabel.Component!

  override func viewDidLoad() {
    super.viewDidLoad()
    component = context.component(PaddedLabel.Component.self, key: "main")
    component.containerView = self.view
    component.setNeedsRender()
  }
}
