import UIKit
import RenderNeutrino

struct StylesheetCounter {

  struct Style {
    static let namespace = "Counter"
    static let wrapper = UIStyle.make(Style.namespace, "wrapper")
    static let label = UIStyle.make(Style.namespace, "label")
    static let button = UIStyle.make(Style.namespace, "button")
  }

  class State: UIState {
    var counter: Int = 0
  }

  class Component: UIComponent<State, UINilProps> {

    override func render(context: UIContextProtocol) -> UINodeProtocol {
      return UINode<UIView>(styles: [Style.wrapper]).children([
        UINode<UILabel>(styles: [Style.label], configure: configureLabel),
        UINode<UIButton>(styles: [Style.button], configure: configureButton)
      ])
    }

    private func configureLabel(configuration: UINode<UILabel>.Configuration) {
      configuration.set(\UILabel.text, "Counter: \(self.state.counter)")
    }

    private func configureButton(configuration: UINode<UIButton>.Configuration) {
      configuration.set(\UIButton.text, "Increase")
      configuration.view.onTap { _ in
        self.state.counter += 1
        self.setNeedsRender()
      }
    }
  }
}
