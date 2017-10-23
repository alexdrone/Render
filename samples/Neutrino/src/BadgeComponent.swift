import UIKit
import RenderNeutrino

struct Badge {

  final class Component: UIComponent<UINilState, UINilProps> {

    override func render(context: UIContextProtocol) -> UINodeProtocol {
      let node = UINode<UIView>(reuseIdentifier: "Badge") { layout in
        layout.set(\UIView.yoga.width, value: 32)
        layout.set(\UIView.yoga.height, value: 32)
        layout.set(\UIView.backgroundColor, value: Color.red)
        layout.set(\UIView.yoga.margin, value: 4)
        layout.set(\UIView.layer.cornerRadius, value: 16)
        layout.set(\UIView.clipsToBounds, value: true)
      }
      return node
    }
  }

}

