import UIKit
import RenderNeutrino

// MARK: - Example 1

class SimpleCounterComponent1: UIComponent<UINilState, UINilProps> {

  /// Builds the node hierarchy for this component.
  override func render(context: UIContextProtocol) -> UINodeProtocol {
    let container = UINode<UIView>(layoutSpec: containerLayoutSpec)
    let label = UINode<UILabel>(layoutSpec: labelLayoutSpec)

    return container.children([
      label,
    ])
  }

  /// Defines the layout and view specification for the container node.
  private func containerLayoutSpec(_ spec: UINode<UIView>.LayoutSpec) {
    // *spec* is a proxy to the rendered view and can be used to configure the backing view for
    // your node...
    spec.set(\UIView.backgroundColor, .blue)

    // ...if necessary you can access to the view directly e.g.
    // spec.view.backgroundColor = .blue has the same effect but it's less optimised.

    // Render uses facebook/yoga to compute view layouts.
    spec.set(\UIView.yoga.width, spec.canvasSize.width)
    spec.set(\UIView.yoga.justifyContent, .center)
  }

  /// Defines the layout and view specification for the label node.
  private func labelLayoutSpec(_ spec: UINode<UILabel>.LayoutSpec) {
    spec.set(\UILabel.font, UIFont.systemFont(ofSize: 12, weight: .bold))
    spec.set(\UILabel.textColor, .white)
    spec.set(\UILabel.yoga.margin, 32)
    spec.set(\UILabel.text, "Number of taps: 0")
  }
}

// MARK: - Example 2

class CounterState: UIState {
  var counter: Int = 0
}

class SimpleCounterComponent2: UIComponent<CounterState, UINilProps> {

  /// Builds the node hierarchy for this component.
  override func render(context: UIContextProtocol) -> UINodeProtocol {
    let container = UINode<UIView>(layoutSpec: containerLayoutSpec)
    let label = UINode<UILabel>(layoutSpec: labelLayoutSpec)

    return container.children([
      label,
      ])
  }

  /// Defines the layout and view specification for the container node.
  private func containerLayoutSpec(_ spec: UINode<UIView>.LayoutSpec) {
    // *spec* is a proxy to the rendered view and can be used to configure the backing view for
    // your node...
    spec.set(\UIView.backgroundColor, .blue)

    // ...if necessary you can access to the view directly e.g.
    // spec.view.backgroundColor = .blue has the same effect but it's less optimised.

    // Render uses facebook/yoga to compute view layouts.
    spec.set(\UIView.yoga.width, spec.canvasSize.width)
    spec.set(\UIView.yoga.justifyContent, .center)

    // We change the state counter when the view is being tapped.
    spec.view.onTap { [weak self] _ in
      self?.state.counter += 1
      self?.setNeedsRender()
    }
  }

  /// Defines the layout and view specification for the label node.
  private func labelLayoutSpec(_ spec: UINode<UILabel>.LayoutSpec) {
    spec.set(\UILabel.font, UIFont.systemFont(ofSize: 12, weight: .bold))
    spec.set(\UILabel.textColor, .white)
    spec.set(\UILabel.yoga.margin, 32)

    // The label now shows the state counter.
    spec.set(\UILabel.text, "Number of taps: \(state.counter)")
  }
}

// MARK: - Example 3

class CounterProps: UIProps {
  var format: String =  "Number of taps: %d"
}

class SimpleCounterComponent3: UIComponent<CounterState, CounterProps> {

  /// Builds the node hierarchy for this component.
  override func render(context: UIContextProtocol) -> UINodeProtocol {
    let container = UINode<UIView>(layoutSpec: containerLayoutSpec)
    let label = UINode<UILabel>(layoutSpec: labelLayoutSpec)

    return container.children([
      label,
      ])
  }

  /// Defines the layout and view specification for the container node.
  private func containerLayoutSpec(_ spec: UINode<UIView>.LayoutSpec) {
    // *spec* is a proxy to the rendered view and can be used to configure the backing view for
    // your node...
    spec.set(\UIView.backgroundColor, .blue)

    // ...if necessary you can access to the view directly e.g.
    // spec.view.backgroundColor = .blue has the same effect but it's less optimised.

    // Render uses facebook/yoga to compute view layouts.
    spec.set(\UIView.yoga.width, spec.canvasSize.width)
    spec.set(\UIView.yoga.justifyContent, .center)

    // We change the state counter when the view is being tapped.
    spec.view.onTap { [weak self] _ in
      self?.state.counter += 1
      self?.setNeedsRender()
    }
  }

  /// Defines the layout and view specification for the label node.
  private func labelLayoutSpec(_ spec: UINode<UILabel>.LayoutSpec) {
    spec.set(\UILabel.font, UIFont.systemFont(ofSize: 12, weight: .bold))
    spec.set(\UILabel.textColor, .white)
    spec.set(\UILabel.yoga.margin, 32)

    // The label now shows the state counter.
    spec.set(\UILabel.text, String(format: props.format, state.counter))
  }
}

// MARK: - Example 4

// We can define a namespace for our style.
struct Style {
  struct Palette {
    static let background: UIColor = .red
    static let text: UIColor = .white
  }

  // *UIStyle* is used to configure and style your view instance at render time.
  static let specContainer = UILayoutSpecStyle<UIView> { spec in
    spec.set(\UIView.backgroundColor, Palette.background)
    spec.set(\UIView.yoga.width, spec.canvasSize.width)
    spec.set(\UIView.yoga.justifyContent, .center)
  }

  static let specLabel = UILayoutSpecStyle<UILabel> { spec in
    spec.set(\UILabel.textColor, Palette.text)
    spec.set(\UILabel.font, UIFont.systemFont(ofSize: 12, weight: .bold))
    spec.set(\UILabel.yoga.margin, 32)
  }
}

class SimpleCounterComponent4: UIComponent<CounterState, CounterProps> {

  /// Builds the node hierarchy for this component.
  override func render(context: UIContextProtocol) -> UINodeProtocol {
    let container = UINode<UIView>(styles: [Style.specContainer],
                                   layoutSpec: containerLayoutSpec)
    let label = UINode<UILabel>(styles: [Style.specLabel],
                                layoutSpec: labelLayoutSpec)
    return container.children([
      label,
    ])
  }

  /// Defines the layout and view specification for the container node.
  private func containerLayoutSpec(_ spec: UINode<UIView>.LayoutSpec) {
    spec.view.onTap { [weak self] _ in
      self?.state.counter += 1
      self?.setNeedsRender()
    }
  }

  /// Defines the layout and view specification for the label node.
  private func labelLayoutSpec(_ spec: UINode<UILabel>.LayoutSpec) {
    spec.set(\UILabel.text, String(format: props.format, state.counter))
  }
}

// MARK: - Example 5

class SimpleCounterComponent5: UIComponent<CounterState, CounterProps> {

  /// Builds the node hierarchy for this component.
  override func render(context: UIContextProtocol) -> UINodeProtocol {
    let container = UINode<UIView>(styles: S.Simple_container.style,
                                   layoutSpec: containerLayoutSpec)
    let label = UINode<UILabel>(styles: S.Simple_label.style,
                                layoutSpec: labelLayoutSpec)
    return container.children([
      label,
      ])
  }

  /// Defines the layout and view specification for the container node.
  private func containerLayoutSpec(_ spec: UINode<UIView>.LayoutSpec) {

    // The view is configured automatically by picking up properties from the stylesheet.
    // I can still access the stylesheet properties programmatically like so:
    let _ = S.MyPalette.background.color
    let _ = S.Simple_label.margin.cgFloat

    spec.view.onTap { [weak self] _ in
      self?.state.counter += 1
      self?.setNeedsRender()
    }
  }

  /// Defines the layout and view specification for the label node.
  private func labelLayoutSpec(_ spec: UINode<UILabel>.LayoutSpec) {
    spec.set(\UILabel.text, String(format: props.format, state.counter))
  }
}
