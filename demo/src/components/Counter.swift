import UIKit
import RenderNeutrino


struct StylesheetCounter {

  class State: UIState {
    var counter: Int = 0
    var even: Bool { return counter % 2 == 0 }
  }

  class Component: UIComponent<State, UINilProps> {
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      let node =  UINode<UIView>(styles: [S.counterWrapper])
      return node.children([
        UINode<UILabel>(styles: [S.counterLabel], layoutSpec: configureLabel),
        UINode<UIButton>(
          styles: [S.counterButton],
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
