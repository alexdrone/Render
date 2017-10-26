import UIKit
import RenderNeutrino

extension UI.Fragments {
  /// A component can be formed by a simple function returning a simple node hierarchy.
  static func badge() -> UINodeProtocol {
    return UINode<UIView>(reuseIdentifier: "Badge") { config in
      config.set(\UIView.yoga.width, 32)
      config.set(\UIView.yoga.height, 32)
      config.set(\UIView.backgroundColor, Color.red)
      config.set(\UIView.yoga.margin, 4)
      config.set(\UIView.layer.cornerRadius, 16)
      config.set(\UIView.clipsToBounds, true)
    }
  }

  static func bodyLabel(text: String) -> UINodeProtocol {
    return UINode<UILabel>() { config in
      config.set(\UILabel.numberOfLines, 0)
      config.set(\UILabel.textColor, .white)
      config.set(\UILabel.text, text)
      config.set(\UILabel.font, UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.light))
    }
  }
}
