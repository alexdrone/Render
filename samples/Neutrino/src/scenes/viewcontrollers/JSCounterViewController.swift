import UIKit
import RenderNeutrino

class JSCounterViewController: UIComponentViewController<JSCounter.Component> {

  override func buildRootComponent() -> JSCounter.Component {
    return context.component(JSCounter.Component.self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    styleNavigationBar()
  }
}


