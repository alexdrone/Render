
import UIKit
import RenderNeutrino

public struct PaddedLabel {

  public class Props: UIPropsProtocol {
    public var isImportant: Bool = true
    public var text: String = "A neutrino (/nuːˈtriːnoʊ/ or /njuːˈtriːnoʊ/) (denoted by the Greek letter ν) is a fermion (an elementary particle with half-integer spin) that interacts only via the weak subatomic force and gravity. The mass of the neutrino is much smaller than that of the other known elementary particles."
    required public init() { }
  }

  public class State: UIStateProtocol {
    var count: Int = 0
    required public init() { }
  }

  public class Component: UIComponent<State, Props> {

    public override func render(context: UIContextProtocol,
                                state: State,
                                props: Props) -> UINodeProtocol {
      print(state)
      let root = UINode<UIView> { layout in
          layout.set(\UIView.backgroundColor, value: props.isImportant ? .orange : .gray)
          layout.set(\UIView.yoga.padding, value: 50)
          layout.set(\UIView.yoga.alignSelf, value: .center)
          layout.set(\UIView.yoga.maxWidth, value: layout.size.width)
      }

      let label = UINode<UILabel>() { layout in
        layout.set(\UILabel.text, value: props.text)
        layout.set(\UILabel.numberOfLines, value: 0)
        layout.set(\UILabel.textColor, value: props.isImportant ? .white : .black)
        layout.set(\UILabel.font, value: UIFont.boldSystemFont(ofSize: 14))
      }

      let count = UINode<UILabel>() { ctx in
        ctx.set(\UILabel.text, value: "counter: \(state.count)")
        ctx.set(\UILabel.backgroundColor, value: .clear)
        ctx.set(\UILabel.textColor, value: .white)
      }

      let button = UINode<UIButton>(reuseIdentifier: "increase") { layout in
        layout.set(\UIButton.yoga.marginTop, value: 10)
        layout.set(\UIButton.backgroundColor, value: #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1))
        layout.view?.onTap { [weak self] _ in
          self?.state.count += 1
          self?.setNeedsRender()
        }
        layout.view?.setTitle("INCREASE", for: .normal)
        layout.view?.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
      }

      root.children([label, count, button])
      return root
    }
  }
}


