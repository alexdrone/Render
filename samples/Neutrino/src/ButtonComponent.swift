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
      let root = UINode<UIButton>(reuseIdentifier: "Button") { layout in
        layout.set(\UIButton.yoga.margin, value: 16)
        layout.set(\UIButton.backgroundColor, value: Color.green)
        layout.view.onTap { _ in
          props.action()
        }
        layout.view.setTitle(props.title, for: .normal)
        layout.view.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
      }
      return root
    }
  }
}
