import UIKit
import RenderNeutrino

extension UI.Props {
  /// The *Button* component properties.
  final class Button: UIPropsProtocol {
    fileprivate var title: String = "undefined"
    fileprivate var action: () -> () = { }
    /// Creats a new button props with an action closure.
    init(title: String, action: @escaping () -> ()) {
      self.title = title
      self.action = action
    }
    /// *UIPropsProtocol* compliancy.
    init() { }
  }
}

extension UI.Components {
  /// The *Button* component subclass.
  final class Button: UIStatelessComponent<UI.Props.Button> {
    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      let props = self.props
      let root = UINode<UIButton>(reuseIdentifier: "Button") { config in
        config.set(\UIButton.yoga.margin, 8)
        config.set(\UIButton.yoga.flexGrow, 0.5)
        config.set(\UIButton.yoga.flexBasis, 0.5)
        config.set(\UIButton.backgroundColor, Color.green)

        config.view.onTap { _ in props.action() }
        config.view.setTitle(props.title, for: .normal)
        config.view.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
      }
      return root
    }
  }
}

extension UI.Props {
  /// The *Counter* component properties.
  final class Counter: UIPropsProtocol {
    fileprivate var count: Int = 0
    /// *UIPropsProtocol* compliancy.
    required init() { }
    /// Creates a new *Counter* props.
    init(count: Int) {
      self.count = count
    }
  }
}

extension UI.Components {
  /// The *Counter* component subclass.
  final class Counter: UIStatelessComponent<UI.Props.Counter> {
    /// Builds the node hierarchy for this component.
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
