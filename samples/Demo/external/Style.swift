import UIKit
import Render

struct Color {
  static let white = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  static let darkerBlack: UIColor = #colorLiteral(red: 0.07600152266, green: 0.08952714743, blue: 0.1140301166, alpha: 1)
  static let black: UIColor = #colorLiteral(red: 0.1870646477, green: 0.2185702622, blue: 0.2767287493, alpha: 1)
  static let green: UIColor = #colorLiteral(red: 0.5828176141, green: 0.8645806313, blue: 0.812251389, alpha: 1)
  static let red: UIColor = #colorLiteral(red: 0.8645806313, green: 0.4114574932, blue: 0.3395885195, alpha: 1)
  static let darkerRed: UIColor = #colorLiteral(red: 0.6853343588, green: 0.3291431345, blue: 0.2744288248, alpha: 1)
  static let darkerGreen: UIColor = #colorLiteral(red: 0.1449353099, green: 0.4921078086, blue: 0.4273921251, alpha: 1)
  static let gray: UIColor = #colorLiteral(red: 0.9998916984, green: 1, blue: 0.9998809695, alpha: 1)
}

struct Typography {
  static let big = UIFont.systemFont(ofSize: 36.0, weight: UIFontWeightBold)
  static let mediumBold = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightBold)
  static let small = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightRegular)
  static let smallBold = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightBold)
  static let smallLight = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightLight)
  static let extraSmallLight = UIFont.systemFont(ofSize: 10.0, weight: UIFontWeightLight)
}

extension UIView {
  var isShimmering: Bool {
    return layer.mask != nil
  }

  func startShimmering() {
    stopShimmering()
    let light: CGColor = UIColor(white: CGFloat(0), alpha: CGFloat(0.1)).cgColor
    let dark: CGColor = UIColor.black.cgColor
    let gradient = CAGradientLayer()
    gradient.colors = [dark, light, dark]
    gradient.frame = CGRect(x: CGFloat(-bounds.size.width),
                            y: CGFloat(0),
                            width: CGFloat(3 * bounds.size.width),
                            height: CGFloat(bounds.size.height))
    gradient.startPoint = CGPoint(x: CGFloat(0.0), y: CGFloat(0.5))
    gradient.endPoint = CGPoint(x: CGFloat(1.0), y: CGFloat(0.525))
    // slightly slanted forward
    gradient.locations = [0.4, 0.5, 0.6]
    layer.mask = gradient
    let animation = CABasicAnimation(keyPath: "locations")
    animation.fromValue = [0.0, 0.1, 0.2]
    animation.toValue = [0.8, 0.9, 1.0]
    animation.duration = 1.5
    animation.repeatCount = Float.infinity
    gradient.add(animation, forKey: "shimmer")
  }
  func stopShimmering() {
    layer.mask = nil
  }
}

extension CGFloat {
  static func random() -> CGFloat {
    return CGFloat(arc4random()) / CGFloat(UInt32.max)
  }
}

extension UIColor {
  static var random: UIColor {
    return UIColor(red: .random(), green: .random(), blue: .random(), alpha: 1.0)
  }
}
