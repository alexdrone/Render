import UIKit
import RenderNeutrino

struct Button {

  final class Props: UIPropsProtocol {
    var title: String = "undefined"
    var action: () -> () = { }

    init(title: String, action: @escaping () -> ()) {
      self.title = title
      self.action = action
    }

    init() { }
  }

  final class Component: UIComponent<UINilState, Props> {

    override func render(context: UIContextProtocol) -> UINodeProtocol {
      let props = self.props
      let root = UINode<UIButton>(reuseIdentifier: "Button") { config in
        config.set(\UIButton.yoga.margin, 8)
        config.set(\UIButton.yoga.flexGrow, 0.5)
        config.set(\UIButton.yoga.flexBasis, 0.5)
        config.set(\UIButton.backgroundColor, Color.green)
        config.view.onTap { _ in
          props.action()
        }
        config.view.setTitle(props.title, for: .normal)
        config.view.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
      }
      return root
    }
  }
}
