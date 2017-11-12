import UIKit
import RenderNeutrino

enum Palette: String {
  case green, pink, text, white, blue

  func `in`(context: UIContextProtocol) -> UIColor {
    return context.jsBridge.variable(namespace: .palette, name: rawValue) ?? .black
  }
}

enum Font: String {
  case extraSmallBold, text, smallBold, mediumBold

  func `in`(context: UIContextProtocol) -> UIFont {
    return context.jsBridge.variable(namespace: .typography, name: rawValue) ?? UIFont()
  }
}



