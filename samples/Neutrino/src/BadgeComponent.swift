import UIKit
import RenderNeutrino

struct Badge {

  final class Component: UIComponent<UINilState, UINilProps> {

    override func render(context: UIContextProtocol) -> UINodeProtocol {
      let node = UINode<UIView>(reuseIdentifier: "Badge") { config in
        config.set(\UIView.yoga.width, 32)
        config.set(\UIView.yoga.height, 32)
        config.set(\UIView.backgroundColor, Color.red)
        config.set(\UIView.yoga.margin, 4)
        config.set(\UIView.layer.cornerRadius, 16)
        config.set(\UIView.clipsToBounds, true)
      }
      return node
    }
  }
}
