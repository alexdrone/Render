
import UIKit
import RenderNeutrino

extension UI.Props {
  /// Props for the *Foo* component.
  final class Foo: UIPropsProtocol {
    var text: String = """
      A neutrino (/nuːˈtriːnoʊ/ or /njuːˈtriːnoʊ/) (denoted by the Greek letter ν) is a fermion
      (an elementary particle with half-integer spin) that interacts only via the weak subatomic
      force and gravity. The mass of the neutrino is much smaller than that of the other known
      elementary particles.
    """
    required init() { }
  }
}

extension UI.States {
  /// State for the *Foo* component.
  final class Foo: UIStateProtocol {
    var count: Int = 0
    required init() { }
  }
}

extension UI.Components {
  /// The *Foo* component subclass.
  final class Foo: UIComponent<UI.States.Foo, UI.Props.Foo> {

    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      let props = self.props
      let state = self.state

      let rootNode = UI.Fragments.Foo_rootNode()
      let label = UI.Fragments.bodyLabel(text: props.text)

      let counter = childComponent(UI.Components.Counter.self,
                                   props: UI.Props.Counter(count: state.count)).asNode()

      let increaseButton = childComponent(UI.Components.Button.self,
                                          key: childKey("increase"),
                                          props: UI.Props.Button(title: "ADD",
                                                                 action: increaseCounter)).asNode()

      let decreaseButton = childComponent(UI.Components.Button.self,
                                          key: childKey("decrease"),
                                          props: UI.Props.Button(title: "REMOVE",
                                                                 action: decreaseCounter)).asNode()

      let buttonsContainer = UI.Fragments.Foo_buttonsContainer(buttons: [
        increaseButton,
        decreaseButton
      ])

      let badges = UI.Fragments.Foo_badgeContainer(count: state.count)

      rootNode.children([label, buttonsContainer, counter, badges])
      return rootNode
    }

    let defaultLayoutAnimator =
      UIViewPropertyAnimator(duration: 0.16, curve: .easeIn, animations: nil)

    private func increaseCounter() {
      self.state.count += 1
      self.setNeedsRender(options: [.animateLayoutChanges(animator: defaultLayoutAnimator)])
    }

    private func decreaseCounter() {
      guard self.state.count > 0 else { return }
      self.state.count -= 1
      self.setNeedsRender(options: [.animateLayoutChanges(animator: defaultLayoutAnimator)])
    }
  }
}

fileprivate extension UI.Fragments {

  static func Foo_rootNode() -> UINode<UIView> {
    return UINode<UIView>(reuseIdentifier: "Foo") { config in
      config.set(\UIView.backgroundColor, Color.black)
      config.set(\UIView.yoga.padding, 8)
      config.set(\UIView.yoga.alignSelf, .center)
      config.set(\UIView.yoga.width, config.canvasSize.width)
    }
  }

  static func Foo_buttonsContainer(buttons: [UINodeProtocol]) -> UINode<UIView> {
    let container = UINode<UIView>(reuseIdentifier: "ButtonsContainer") { config in
      config.set(\UIView.yoga.flexDirection, .row)
    }
    container.children(buttons)
    return container
  }

  static func Foo_badgeContainer(count: Int) -> UINodeProtocol {
    let container = UINode<UIView>(reuseIdentifier: "BadgesContainer") { config in
      config.set(\UIView.yoga.flexDirection, .row)
      config.set(\UIView.yoga.flexWrap, .wrap)
    }

    let badges: [UINodeProtocol] = Array(0..<count).map { _ in UI.Fragments.badge() }
    container.children(badges)
    return container
  }

}
