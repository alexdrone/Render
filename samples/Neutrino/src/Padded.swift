
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
    weak var wrapperView: UILabel?

    public override func render() {
      resetNode()

      set(\.backgroundColor) { props, size in props.isImportant ? #colorLiteral(red: 0.1870646477, green: 0.2185702622, blue: 0.2767287493, alpha: 1) : #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1) }
      set(\.yoga.padding, value: 50)
      set(\.yoga.alignSelf, value: .center)
      set(\.yoga.maxWidth) { _, size in size.width }

      let label = UIProplessNode<UILabel>()
      label.set(\.text, value: props.text)
      label.set(\.numberOfLines, value: 0)
      label.set(\.textColor) { size in self.props.isImportant ? .white : .black }
      label.set(\.font) { size in
        size.width > size.height ? UIFont.boldSystemFont(ofSize: 14) : UIFont.systemFont(ofSize: 11)
      }
      label.set(\.backgroundColor, value: .clear)

      let count = UIProplessNode<UILabel>()
      count.set(\.text) { _, size in "counter: \(self.state.count)" }
      count.set(\.backgroundColor, value: .clear)

      let button = UIProplessNode<UIButton>(reuseIdentifier: "increase", create: {
        let button = UIButton(type: .custom)
        button.setTitle("INCREASE", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.onTap { _ in
          self.state.count += 1
          self.render()
        }
        return button
      })

      button.set(\.yoga.marginTop, value: 10)
      button.set(\.backgroundColor, value: #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1))
      set(children: [label, count, button])

      super.render()
    }

    /// The view just got layed out.
    public override func nodeDidLayout(_ node: UINodeProtocol, view: UIView) {
    }

  }
}

@IBDesignable @objc public class PaddedLabelView: UINodeView {

  public override func constructNode() -> UINodeProtocol {
    print("hej")
    return PaddedLabel.Node(key: "a")
  }
}

