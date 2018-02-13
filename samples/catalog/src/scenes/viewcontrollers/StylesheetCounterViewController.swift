import UIKit
import RenderNeutrino

class StylesheetCounterViewController: UIComponentViewController<StylesheetCounter.Component> {

  override func buildRootComponent() -> StylesheetCounter.Component {
    return context.component(StylesheetCounter.Component.self)
  }

  override func viewDidLoad() {
    styleNavigationBarComponent(title: "Simple Counter (w/ Stylesheet)")
    super.viewDidLoad()
    shouldRenderAlongsideSizeTransitionAnimation = true
  }
}

