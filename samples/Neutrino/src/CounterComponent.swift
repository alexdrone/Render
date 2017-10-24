import UIKit
import RenderNeutrino

struct Counter {

  final class Props: UIPropsProtocol {
    var count: Int = 0
    required init() { }
    init(count: Int) {
      self.count = count
    }
  }

  final class Component: UIComponent<UINilState, Props> {

    override func render(context: UIContextProtocol) -> UINodeProtocol {
      let props = self.props
      let node = UINode<UILabel>(reuseIdentifier: "Count") { config in
        config.set(\UILabel.text, "\(props.count)")
        config.set(\UILabel.backgroundColor, Color.red)
        config.set(\UILabel.textColor, .white)
        config.set(\UILabel.font, Typography.mediumBold)
        config.set(\UILabel.textAlignment, .center)
        config.set(\UILabel.yoga.width, 32)
        config.set(\UILabel.yoga.height, 32)
        config.set(\UILabel.layer.cornerRadius, 16)
        config.set(\UILabel.clipsToBounds, true)
        config.set(\UILabel.yoga.alignSelf, .center)
        config.set(\UILabel.yoga.justifyContent, .center)
        config.set(\UILabel.yoga.margin, 16)
      }
      return node
    }
  }

}


