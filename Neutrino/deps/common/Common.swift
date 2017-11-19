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
  public typealias CGFloatRatio = CGFloat

  /// A *UIView* node that lays out its children horizontally.
  /// - parameter reuseIdentifier: Optional reuse identifier for this container view.
  /// - parameter widthRatio: The width of the container as expressed as proportion of the canvas.
  /// - parameter configure: Additional custom view overrides.
  public static func Row(reuseIdentifier: String = "row",
                         widthRatio: CGFloatRatio? = nil,
                         configure: UIViewConfiguration? = nil) -> UINode<UIView> {
    return Container(reuseIdentifier: reuseIdentifier,
                     direction: .row,
                     widthRatio: widthRatio,
                     configure: configure)
  }

  /// A *UIView* node that lays out its children vertically.
  /// - parameter reuseIdentifier: Optional reuse identifier for this container view.
  /// - parameter widthRatio: The width of the container as expressed as proportion of the canvas.
  /// - parameter configure: Additional custom view overrides.
  public static func Column(reuseIdentifier: String = "row",
                            widthRatio: CGFloatRatio? = nil,
                            configure: UIViewConfiguration? = nil) -> UINode<UIView> {
    return Container(reuseIdentifier: reuseIdentifier,
                     direction: .column,
                     widthRatio: widthRatio,
                     configure: configure)
  }

  /// Concrete implementation for *Row* and *Column* containers.
  private static func Container(reuseIdentifier: String,
                                direction: YGFlexDirection,
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
      configure?(config)
    }
  }

  /// A simple text node (backed by a *UILabel* view instance).
  /// - parameter reuseIdentifier: Optional reuse identifier for this label.
  /// - parameter text: The label text.
  /// - parameter configure: Additional custom view overrides.
  public static func Text(reuseIdentifier: String = "text",
                          text: String,
                          configure: UILabelConfiguration? = nil) -> UINode<UILabel> {
    return UINode<UILabel>(reuseIdentifier: reuseIdentifier) { config in
      config.set(\UILabel.text, text)
      config.set(\UILabel.numberOfLines, 0)
      configure?(config)
    }
  }
}
