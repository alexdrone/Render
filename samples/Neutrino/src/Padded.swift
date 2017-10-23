
import UIKit
import RenderNeutrino

public struct PaddedLabel {

  public class Props: UIPropsProtocol {
    public var text: String = "A neutrino (/nuːˈtriːnoʊ/ or /njuːˈtriːnoʊ/) (denoted by the Greek letter ν) is a fermion (an elementary particle with half-integer spin) that interacts only via the weak subatomic force and gravity. The mass of the neutrino is much smaller than that of the other known elementary particles."
    required public init() { }
  }

  public class State: UIStateProtocol {
    var count: Int = 0
    required public init() { }
  }

  public class Component: UIComponent<State, Props> {

    private weak var counterLabel: UILabel?

    public override func render(context: UIContextProtocol) -> UINodeProtocol {
      let props = self.props
      let state = self.state

      let root = UINode<UIScrollView> { layout in
        layout.set(\UIScrollView.backgroundColor, value: Color.black)
        layout.set(\UIScrollView.yoga.padding, value: 8)
        layout.set(\UIScrollView.yoga.alignSelf, value: .center)
        layout.set(\UIScrollView.yoga.width, value: layout.canvasSize.width)
        layout.set(\UIScrollView.yoga.height, value: context.canvasView?.bounds.size.height ?? 0)
      }

      let label = UINode<UILabel>() { layout in
        layout.set(\UILabel.numberOfLines, value: 0)
        layout.set(\UILabel.textColor, value: Color.white)
        layout.set(\UILabel.text, value: props.text)
        layout.set(\UILabel.font,
                   value: UIFont.systemFont(ofSize: 12 + CGFloat(state.count)/2,
                                            weight: UIFont.Weight.light))
      }

      let count = UINode<UILabel>() { layout in
        layout.set(\UILabel.text, value: "\(state.count)")
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

      let button = UINode<UIButton>(reuseIdentifier: "Increase") { layout in
        layout.set(\UIButton.yoga.margin, value: 16)
        layout.set(\UIButton.backgroundColor, value: Color.green)

        let animator = UIViewPropertyAnimator(duration: 1, dampingRatio: 1, animations: nil)
        layout.set(\UIButton.alpha, animator: animator, value: 0.1 + (CGFloat(state.count)+1)/10)
        layout.view.onTap { [weak self] _ in
          guard let `self` = self else { return }
          self.state.count = self.state.count == 9 ? 0 : self.state.count + 1
          // Render animated.
          let animator = UIViewPropertyAnimator(duration: 1, dampingRatio: 0.7, animations: nil)
          self.setNeedsRender(layoutAnimator: animator)
        }
        layout.view.setTitle("INCREASE", for: .normal)
        layout.view.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
      }

      root.children([button, count, label])
      return root
    }
  }
}

func randomCGFloat() -> CGFloat {
  return CGFloat(Float(arc4random()) /  Float(UInt32.max))
}

