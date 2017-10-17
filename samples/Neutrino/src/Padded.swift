
import UIKit
import RenderNeutrino

public struct PaddedLabel {

  public class Props: UINodePropsProtocol {
    public var isImportant: Bool = true
    public var text: String = "A neutrino (/nuːˈtriːnoʊ/ or /njuːˈtriːnoʊ/) (denoted by the Greek letter ν) is a fermion (an elementary particle with half-integer spin) that interacts only via the weak subatomic force and gravity. The mass of the neutrino is much smaller than that of the other known elementary particles."
    required public init() { }
  }

  public class State: UIStateProtocol {
    var count: Int = 0
    required public init() { }
  }

  public class Node: UIStatefulNode<UIView, State, Props> {

    public override func build(rootCtx: _UINode<UIView, State, Props>.Context) {
      configure { ctx in
        ctx.set(\UIView.backgroundColor, value: ctx.props.isImportant ? .orange : .gray)
        ctx.set(\UIView.yoga.padding, value: 50)
        ctx.set(\UIView.yoga.alignSelf, value: .center)
        ctx.set(\UIView.yoga.maxWidth, value: ctx.size.width)
      }

      let label = UINode<UILabel>() { ctx in
        ctx.set(\UILabel.text, value: rootCtx.props.text)
        ctx.set(\UILabel.numberOfLines, value: 0)
        ctx.set(\UILabel.textColor, value: rootCtx.props.isImportant ? .white : .black)
        ctx.set(\UILabel.font, value: UIFont.boldSystemFont(ofSize: 14))
      }

      let count = UINode<UILabel>() { ctx in
        ctx.set(\UILabel.text, value: "counter: \(rootCtx.state.count)")
        ctx.set(\UILabel.backgroundColor, value: .clear)
        ctx.set(\UILabel.textColor, value: .white)
      }

      func createIncreaseButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle("INCREASE", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.onTap { _ in
          rootCtx.state.count += 1
          rootCtx.node.reconcile()
        }
        return button
      }

      let button = UINode<UIButton>(reuseIdentifier: "increase",
                                    create: createIncreaseButton) { ctx in
        ctx.set(\UIButton.yoga.marginTop, value: 10)
        ctx.set(\UIButton.backgroundColor, value: #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1))
      }

      children([label, count, button])
    }
  }
}

@IBDesignable @objc public class PaddedLabelView: UINodeView {

  public override func constructNode() -> UINodeProtocol {
    return PaddedLabel.Node(key: "Test")
  }
}

