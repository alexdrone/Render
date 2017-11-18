import UIKit

public typealias CGFloatRatio = CGFloat

/// Common components fragments.
public struct UICommons {
  public typealias _UIViewC = UINode<UIView>.UINodeConfigurationClosure
  public typealias _UILabelC = UINode<UILabel>.UINodeConfigurationClosure

  /// A *UIView* node that lays out its children horizontally.
  public static func RowContainer(reuseIdentifier: String = "rowContainer",
                                  background: UIColor = .clear,
                                  padding: CGFloat = 0,
                                  margin: CGFloat = 0,
                                  widthRatio: CGFloatRatio? = nil,
                                  configure: _UIViewC? = nil) -> UINode<UIView> {
    return Container(reuseIdentifier: reuseIdentifier,
                     direction: .row,
                     background: background,
                     padding: padding,
                     margin: margin,
                     widthRatio: widthRatio,
                     configure: configure)
  }

  /// A *UIView* node that lays out its children vertically.
  public static func ColumnContainer(reuseIdentifier: String = "columnContainer",
                                     background: UIColor = .clear,
                                     padding: CGFloat = 0,
                                     margin: CGFloat = 0,
                                     widthRatio: CGFloatRatio? = nil,
                                     configure: _UIViewC? = nil) -> UINode<UIView> {
    return Container(reuseIdentifier: reuseIdentifier,
                     direction: .column,
                     background: background,
                     padding: padding,
                     margin: margin,
                     widthRatio: widthRatio,
                     configure: configure)
  }

  private static func Container(reuseIdentifier: String,
                                direction: YGFlexDirection,
                                background: UIColor = .clear,
                                padding: CGFloat = 0,
                                margin: CGFloat = 0,
                                widthRatio: CGFloatRatio? = nil,
                                configure: _UIViewC? = nil) -> UINode<UIView> {
    func makeContainer() -> UIView {
      let view = UIView()
      view.backgroundColor = background
      view.yoga.padding = padding
      view.yoga.margin = margin
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
  public static func Text(reuseIdentifier: String = "text",
                          text: String,
                          alignment: NSTextAlignment = .left,
                          font: UIFont = UIFont.systemFont(ofSize: 12),
                          color: UIColor = .black,
                          margin: CGFloat = 2,
                          configure: _UILabelC? = nil) -> UINode<UILabel> {
    return UINode<UILabel>(reuseIdentifier: reuseIdentifier) { config in
      config.set(\UILabel.text, text)
      config.set(\UILabel.numberOfLines, 0)
      config.set(\UILabel.font, font)
      config.set(\UILabel.textColor, color)
      config.set(\UILabel.yoga.margin, margin)
    }
  }
}
