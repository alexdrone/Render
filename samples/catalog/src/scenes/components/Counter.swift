import UIKit
import RenderNeutrino


struct StylesheetCounter {

  class State: UIState {
    var counter: Int = 0
    var even: Bool { return counter % 2 == 0 }
  }

  class Component: UIComponent<State, UINilProps> {
    override func render(context: UIContextProtocol) -> UINodeProtocol {

      return UINode<UIView>(styles: ["Counter.wrapper"]).children([
        UINode<UILabel>(styles: ["Counter.label"], layoutSpec: configureLabel),
        UINode<UIButton>(styles: "Counter.button".withModifiers(["even": state.even]),
                         layoutSpec: configureButton)
      ])
    }

    private func configureLabel(configuration: UINode<UILabel>.LayoutSpec) {
      let text = self.state.even ? "Even" : "Odd"
      configuration.set(\UILabel.text, "\(text): \(self.state.counter)")
    }

    private func configureButton(configuration: UINode<UIButton>.LayoutSpec) {
      configuration.set(\UIButton.text, "Increase")
      configuration.view.onTap { _ in
        self.state.counter += 1
        self.setNeedsRender()
      }
    }
  }
}
