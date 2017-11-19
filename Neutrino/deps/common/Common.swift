import UIKit

public struct UI {
  /// Namespace reserved for app fragments.
  public struct Fragments { }
  /// Namespace reserved for app components.
  public struct Components { }
  /// Namespace reserved for components props.
  public struct Props { }
  /// Namespace reserved for components states.
  public struct States { }
}

/// Common components fragments.
extension UI.Fragments {
  public typealias UIViewConfiguration = UINode<UIView>.ConfigurationClosure
  public typealias UILabelConfiguration = UINode<UILabel>.ConfigurationClosure
  public typealias UIButtonConfiguration = UINode<UIButton>.ConfigurationClosure
  public typealias CGFloatRatio = CGFloat

  /// A *UIView* node that lays out its children horizontally.
  /// - parameter reuseIdentifier: Optional reuse identifier for this container view.
  /// - parameter widthRatio: The width of the container as expressed as proportion of the canvas.
  /// - parameter configure: Additional custom view overrides.
  public static func Row(reuseIdentifier: String = "row",
                         backgroundColor: UIColor = .clear,
                         widthRatio: CGFloatRatio? = nil,
                         configure: UIViewConfiguration? = nil) -> UINode<UIView> {
    return Container(reuseIdentifier: reuseIdentifier,
                     direction: .row,
                     backgroundColor: backgroundColor,
                     widthRatio: widthRatio,
                     configure: configure)
  }

  /// A *UIView* node that lays out its children vertically.
  /// - parameter reuseIdentifier: Optional reuse identifier for this container view.
  /// - parameter widthRatio: The width of the container as expressed as proportion of the canvas.
  /// - parameter configure: Additional custom view overrides.
  public static func Column(reuseIdentifier: String = "row",
                            backgroundColor: UIColor = .clear,
                            widthRatio: CGFloatRatio? = nil,
                            configure: UIViewConfiguration? = nil) -> UINode<UIView> {
    return Container(reuseIdentifier: reuseIdentifier,
                     direction: .column,
                     backgroundColor: backgroundColor,
                     widthRatio: widthRatio,
                     configure: configure)
  }

  /// Concrete implementation for *Row* and *Column* containers.
  private static func Container(reuseIdentifier: String,
                                direction: YGFlexDirection,
                                backgroundColor: UIColor = .clear,
                                widthRatio: CGFloatRatio? = nil,
                                configure: UIViewConfiguration? = nil) -> UINode<UIView> {
    func makeContainer() -> UIView {
      let view = UIView()
      view.yoga.flexDirection = direction
      return view
    }
    return UINode<UIView>(reuseIdentifier: reuseIdentifier, create: makeContainer) { config in
      if let ratio = widthRatio {
        config.view.yoga.width = config.canvasSize.width * ratio
      }
      config.set(\UIView.backgroundColor, backgroundColor)
      configure?(config)
    }
  }

  /// A simple text node (backed by a *UILabel* view instance).
  /// - parameter reuseIdentifier: Optional reuse identifier for this label.
  /// - parameter text: The label text.
  /// - parameter configure: Additional custom view overrides.
  public static func Text(reuseIdentifier: String = "text",
                          text: String,
                          foregroundColor: UIColor = .black,
                          configure: UILabelConfiguration? = nil) -> UINode<UILabel> {
    func makeLabel() -> UILabel {
      let view = UILabel()
      view.textColor = foregroundColor
      return view
    }
    return UINode<UILabel>(reuseIdentifier: reuseIdentifier, create: makeLabel) { config in
      config.set(\UILabel.text, text)
      config.set(\UILabel.numberOfLines, 0)
      configure?(config)
    }
  }

  /// A simple text node (backed by a *UIButton* view instance).
  /// - parameter reuseIdentifier: Optional reuse identifier for this label.
  /// - parameter text: The button title.
  /// - parameter configure: Additional custom view overrides.
  public static func Button(reuseIdentifier: String = "button",
                            text: String,
                            foregroundColor: UIColor = .black,
                            backgroundColor: UIColor = .white,
                            onTouchUpInside: @escaping () -> Void = { },
                            configure: UIButtonConfiguration? = nil) -> UINode<UIButton> {
    func makeButton() -> UIButton {
      let view = UIButton()
      view.backgroundColorImage = backgroundColor
      view.textColor = foregroundColor
      view.depthPreset = .depth1
      view.cornerRadiusPreset = .cornerRadius1
      view.yoga.padding = MarginPreset.small.cgFloatValue
      view.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
      return view
    }
    return UINode<UIButton>(reuseIdentifier: reuseIdentifier, create: makeButton) { config in
      config.view.setTitle(text, for: .normal)
      config.view.backgroundColorImage = backgroundColor
      config.view.textColor = foregroundColor
      config.view.onTap { _ in onTouchUpInside() }
    }
  }

  /// A *UIView* istance with a *UITapGestureRecognizer* registered to it.
  /// - parameter reuseIdentifier: Optional reuse identifier for this label.
  /// - parameter configure: Additional custom view overrides.
  public static func TapRecognizer(reuseIdentifier: String = "tapRecognizer",
                                   onTouchUpInside: @escaping () -> Void = { },
                                   configure: UIViewConfiguration? = nil) -> UINode<UIView> {
    return UINode<UIView>(reuseIdentifier: reuseIdentifier) { config in
      config.view.onTap { _ in onTouchUpInside() }
      configure?(config)
    }
  }

}
