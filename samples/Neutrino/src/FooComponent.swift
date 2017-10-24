
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

      let root = UINode<UIScrollView> { config in
        config.set(\UIScrollView.backgroundColor, .black)
        config.set(\UIScrollView.yoga.padding, 8)
        config.set(\UIScrollView.yoga.alignSelf, .center)
        config.set(\UIScrollView.yoga.width, config.canvasSize.width)
        config.set(\UIScrollView.yoga.height, context.canvasView?.bounds.size.height ?? 0)
      }

      let label = UINode<UILabel>() { config in
        config.set(\UILabel.numberOfLines, 0)
        config.set(\UILabel.textColor, .white)
        config.set(\UILabel.text, props.text)
        config.set(\UILabel.font,
                   UIFont.systemFont(ofSize: 12 + CGFloat(state.count)/2,
                                     weight: UIFont.Weight.light))
      }

      let animator = UIViewPropertyAnimator(duration: 1, dampingRatio: 0.8, animations: nil)

      let counterProps = Counter.Props(count: state.count)
      let counter = context.transientComponent(Counter.Component.self,
                                               props: counterProps,
                                               parent: nil).render(context: context)

      let increaseButtonProps = Button.Props(title: "INCREASE") {
        self.state.count += 1
        self.setNeedsRender(layoutAnimator: animator)
      }
      let increaseButton = context.component(Button.Component.self,
                                             key: "increase",
                                             props: increaseButtonProps,
                                             parent: self).render(context: context)

      let decreaseButtonProps = Button.Props(title: "DECREASE") {
        guard self.state.count > 0 else { return }
        self.state.count -= 1
        self.setNeedsRender(layoutAnimator: animator)
      }
      let decreaseButton = context.component(Button.Component.self,
                                             key: "decrease",
                                             props: decreaseButtonProps,
                                             parent: self).render(context: context)

      let badgesWrapper = UINode<UIView>(reuseIdentifier: "BadgesWrapper") { config in
        config.set(\UIView.yoga.flexDirection, .row)
        config.set(\UIView.yoga.flexWrap, .wrap)
      }

      let badges: [UINodeProtocol] = Array(0..<state.count).map { _ in
        context.transientComponent(Badge.Component.self,
                                   props: UINilProps.nil,
                                   parent: self).render(context: context)
      }
      badgesWrapper.children(badges)

      root.children([increaseButton, decreaseButton, counter, badgesWrapper, label])
      return root
    }
  }
}




