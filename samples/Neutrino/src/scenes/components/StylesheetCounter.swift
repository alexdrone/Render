import UIKit
import RenderNeutrino

struct StylesheetCounter {

  struct Style {
    enum Wrapper: String, UIStylesheet {
      static var name: String = "Counter.Wrapper"
      case `_`
    }
    enum Button: String, UIStylesheet {
      static var name: String = "Counter.Button"
      case `_`
    }
    enum Label: String, UIStylesheet {
      static var name: String = "Counter.Label"
      case `_`
    }
  }

  class State: UIState {
    var counter: Int = 0
  }

  class Component: UIComponent<State, UINilProps> {

    override func render(context: UIContextProtocol) -> UINodeProtocol {
      return UINode<UIView>(style: Style.Wrapper._, configure: configureWrapper).children([
        UINode<UILabel>(style: Style.Label._, configure: configureLabel),
        UINode<UIButton>(style: Style.Button._, configure: configureButton)
      ])
    }

    private func configureWrapper(configuration: UINode<UIView>.Configuration) {
      configuration.set(\UIView.yoga.width, configuration.canvasSize.width)
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
