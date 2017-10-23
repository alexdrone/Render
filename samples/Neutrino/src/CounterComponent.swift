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
      let node = UINode<UILabel>(reuseIdentifier: "Count") { layout in
        layout.set(\UILabel.text, value: "\(props.count)")
        layout.set(\UILabel.backgroundColor, value: Color.red)
        layout.set(\UILabel.textColor, value: .white)
        layout.set(\UILabel.font, value: Typography.mediumBold)
        layout.set(\UILabel.textAlignment, value: .center)
        layout.set(\UILabel.yoga.width, value: 32)
        layout.set(\UILabel.yoga.height, value: 32)
        layout.set(\UILabel.layer.cornerRadius, value: 16)
        layout.set(\UILabel.clipsToBounds, value: true)
        layout.set(\UILabel.yoga.alignSelf, value: .center)
        layout.set(\UILabel.yoga.margin, value: 16)
      }
      return node
    }
  }

}


