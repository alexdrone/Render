import UIKit
import RenderNeutrino


struct JSCounter {

  /// State for the *JSCounter* component.
  final class State: UIStateProtocol {
    var count: Int = 0
    required init() { }
  }

  /// The *JsCounter* component properties.
  final class Props: UIPropsProtocol, Codable {
    var count: Int = 0
    /// *UIPropProtocol* compliancy.
    required init() { }
    /// Creates a new *Counter* props.
    init(count: Int) {
      self.count = count
    }
  }

  /// The *JsCounter* component subclass.
  final class Component: UIComponent<State, UINilProps> {

    override func requiredJSFragment() -> [String] {
      return ["counter-fragment"]
    }

    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      let jsprops = JSCounter.Props(count: self.state.count)
      let node = context.jsBridge.buildFragment(function: "Counter",
                                                props: jsprops,
                                                canvasSize: context.screen.canvasSize)
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
