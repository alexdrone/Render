
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

    public override func render(context: UIContextProtocol) -> UINodeProtocol {
      let props = self.props
      let state = self.state

      let root = UINode<UIScrollView> { layout in
        layout.set(\UIScrollView.backgroundColor, value: props.isImportant ? .orange : .gray)
        layout.set(\UIScrollView.yoga.padding, value: 50)
        layout.set(\UIScrollView.yoga.alignSelf, value: .center)
        layout.set(\UIScrollView.yoga.width, value: layout.canvasSize.width)
        layout.set(\UIScrollView.yoga.maxHeight, value: context.canvasView?.bounds.size.height ?? 0)
      }

      let label = UINode<UILabel>() { layout in
        layout.set(\UILabel.numberOfLines, value: 100)
        layout.set(\UILabel.textColor, value: props.isImportant ? .white : .black)
        layout.set(\UILabel.font, value: UIFont.boldSystemFont(ofSize: 14))

        var text = Array(0+6...state.count+6).reduce("", { str, _ in str + props.text })
        layout.set(\UILabel.text, value: text)
      }

      let count = UINode<UILabel>() { layout in
        layout.set(\UILabel.text, value: "counter: \(state.count)")
        layout.set(\UILabel.backgroundColor, value: .clear)
        layout.set(\UILabel.textColor, value: .white)
        layout.set(\UILabel.yoga.padding, value: CGFloat(state.count*40))
      }

      let button = UINode<UIButton>(reuseIdentifier: "increase") { layout in
        layout.set(\UIButton.yoga.marginTop, value: 10)
        layout.set(\UIButton.backgroundColor, value: #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1))
        let animator = UIViewPropertyAnimator(duration: 1, dampingRatio: 1, animations: nil)
        layout.set(\UIButton.alpha, animator: animator, value: randomCGFloat())
        layout.view.onTap { [weak self] _ in
          self?.state.count += 1
          let animator = UIViewPropertyAnimator(duration: 3, dampingRatio: 0.3, animations: nil)
          self?.setNeedsRender(layoutAnimator: animator)
        }
        layout.view.setTitle("INCREASE", for: .normal)
        layout.view.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
      }

      root.children([label, count, button])
      return root
    }
  }
}

func randomCGFloat() -> CGFloat {
  return CGFloat(Float(arc4random()) /  Float(UInt32.max))
}

