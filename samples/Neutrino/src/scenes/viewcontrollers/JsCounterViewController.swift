import UIKit
import RenderNeutrino

class JsCounterViewController: UIComponentViewController<UI.Components.JsCounter> {

  override func buildRootComponent() -> UI.Components.JsCounter {
    return context.component(UI.Components.JsCounter.self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    styleNavigationBar()
  }
}


