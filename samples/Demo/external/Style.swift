import UIKit
import Render

struct Color {
  static let white = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  static let black: UIColor = #colorLiteral(red: 0.1870646477, green: 0.2185702622, blue: 0.2767287493, alpha: 1)
  static let green: UIColor = #colorLiteral(red: 0.5828176141, green: 0.8645806313, blue: 0.812251389, alpha: 1)
  static let red: UIColor = #colorLiteral(red: 0.8645806313, green: 0.4114574932, blue: 0.3395885195, alpha: 1)
  static let darkerGreen: UIColor = #colorLiteral(red: 0.1449353099, green: 0.4921078086, blue: 0.4273921251, alpha: 1)
  static let gray: UIColor = #colorLiteral(red: 0.9998916984, green: 1, blue: 0.9998809695, alpha: 1)
}

struct Typography {
  static let mediumBold = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightBold)
  static let small = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightRegular)
  static let smallBold = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightBold)
  static let smallLight = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightLight)
}
