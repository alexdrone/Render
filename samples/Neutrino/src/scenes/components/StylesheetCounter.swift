import UIKit
import RenderNeutrino

struct StylesheetCounter {

  class State: UIState {
    var counter: Int = 0
  }

  class Component: UIComponent<State, UINilProps> {

    override func render(context: UIContextProtocol) -> UINodeProtocol {
      return UINode<UIView>(style: "Counter.wrapper").children([
        UINode<UILabel>(style: "Counter.label", configure: configureLabel),
        UINode<UIButton>(style: "Counter.button", configure: configureButton)
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
