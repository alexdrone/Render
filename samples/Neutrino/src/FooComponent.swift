
import UIKit
import RenderNeutrino

struct Foo {

  final class Props: UIPropsProtocol {
   var text: String = """
      A neutrino (/nuːˈtriːnoʊ/ or /njuːˈtriːnoʊ/) (denoted by the Greek letter ν) is a fermion
      (an elementary particle with half-integer spin) that interacts only via the weak subatomic
      force and gravity. The mass of the neutrino is much smaller than that of the other known
      elementary particles.
    """
    required init() { }
  }

  final class State: UIStateProtocol {
    var count: Int = 0
    required init() { }
  }

  final class Component: UIComponent<State, Props> {
    override func render(context: UIContextProtocol) -> UINodeProtocol {

      let props = self.props
      let state = self.state

      let defaultLayoutAnimator = UIViewPropertyAnimator(duration: 0.16,
                                                         curve: .easeIn,
                                                         animations: nil)

      let root = UINode<UIView>(reuseIdentifier: "Foo") { config in
        config.set(\UIView.backgroundColor, Color.black)
        config.set(\UIView.yoga.padding, 8)
        config.set(\UIView.yoga.alignSelf, .center)
        config.set(\UIView.yoga.width, config.canvasSize.width)
      }

      let label = UINode<UILabel>() { config in
        config.set(\UILabel.numberOfLines, 0)
        config.set(\UILabel.textColor, .white)
        config.set(\UILabel.text, props.text)
        config.set(\UILabel.font,
                   UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.light))
      }

      let counterProps = Counter.Props(count: state.count)
      let counter = childComponent(Counter.Component.self, props: counterProps).asNode()

      let increaseButtonProps = Button.Props(title: "ADD") {
        self.state.count += 1
        self.setNeedsRender(options: [.animateLayoutChanges(animator: defaultLayoutAnimator)])
      }
      let increaseButton = childComponent(Button.Component.self,
                                          key: "increase",
                                          props: increaseButtonProps).asNode()

      let decreaseButtonProps = Button.Props(title: "REMOVE") {
        guard self.state.count > 0 else { return }
        self.state.count -= 1
        self.setNeedsRender(options: [.animateLayoutChanges(animator: defaultLayoutAnimator)])
      }
      let decreaseButton = childComponent(Button.Component.self,
                                          key: "decrease",
                                          props: decreaseButtonProps).asNode()

      let buttonsWrapper = UINode<UIView>(reuseIdentifier: "ButtonWrapper") { config in
        config.set(\UIView.yoga.flexDirection, .row)
      }
      buttonsWrapper.children([increaseButton, decreaseButton])

      let badgesWrapper = UINode<UIView>(reuseIdentifier: "BadgesWrapper") { config in
        config.set(\UIView.yoga.flexDirection, .row)
        config.set(\UIView.yoga.flexWrap, .wrap)
      }

      let badges: [UINodeProtocol] = Array(0..<state.count).map { _ in
        childComponent(Badge.Component.self).asNode()
      }
      badgesWrapper.children(badges)

      root.children([label, buttonsWrapper, counter, badgesWrapper])
      return root
    }
  }
}
