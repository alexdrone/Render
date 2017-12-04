import UIKit
import RenderNeutrino

class JsCounterViewController: UIComponentViewController<UI.Components.JsCounter> {

  override func buildRootComponent() -> UI.Components.JsCounter {
    return context.component(UI.Components.JsCounter.self,
                             key: "jscounter",
                             props: UINilProps.nil,
                             parent: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = Palette.primary.color
    self.navigationItem.title = "JSCOUNTER FRAGMENT"
    styleNavigationBar()
  }
}


