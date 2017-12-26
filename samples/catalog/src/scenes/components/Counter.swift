import UIKit
import RenderNeutrino

struct StylesheetCounter {

  class State: UIState {
    var counter: Int = 0
    var even: Bool { return counter % 2 == 0 }
  }

  class Component: UIComponent<State, UINilProps> {
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      // Styles.
      let namespace = "Counter"
      let wrapperStyle = UIStyle.make(namespace, "wrapper")
      let labelStyle = UIStyle.make(namespace, "label")
      let buttonStyle = UIStyle.make(namespace, "button")

      return UINode<UIView>(styles: [wrapperStyle]).children([
        UINode<UILabel>(styles: [labelStyle], configure: configureLabel),
        UINode<UIButton>(styles: buttonStyle.withModifiers(["even": state.even]),
                         configure: configureButton)
      ])
    }

    private func configureLabel(configuration: UINode<UILabel>.Configuration) {
      let text = self.state.even ? "Even" : "Odd"
      configuration.set(\UILabel.text, "\(text): \(self.state.counter)")
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
