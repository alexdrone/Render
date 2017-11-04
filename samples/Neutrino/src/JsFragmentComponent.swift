import UIKit
import RenderNeutrino

extension UI.States {
  /// State for the *JsCounter* component.
  final class JsCounter: UIStateProtocol {
    var count: Int = 0
    required init() { }
  }
}

extension UI.Props {
  /// The *JsCounter* component properties.
  final class JsFragmentCounter: UIPropsProtocol, Codable {
    var count: Int = 0
    /// *UIPropsProtocol* compliancy.
    required init() { }
    /// Creates a new *Counter* props.
    init(count: Int) {
      self.count = count
    }
  }
}

extension UI.Components {
  /// The *JsCounter* component subclass.
  final class JsCounter: UIComponent<UI.States.JsCounter, UINilProps> {

    required init(context: UIContextProtocol, key: String?) {
      super.init(context: context, key: key)
      context.jsBridge.loadDefinition(file: "Fragment")
    }

    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      let jsprops = UI.Props.JsFragmentCounter(count: self.state.count)
      let node = context.jsBridge.buildFragment(function: "Counter",
                                                props: jsprops,
                                                canvasSize: context.canvasSize)

      node.nodeWithKey("button")?.overrides = { view in
        view.onTap { [weak self] _ in
          self?.state.count += 1
          self?.setNeedsRender()
        }
      }
      return node
    }
  }
}
