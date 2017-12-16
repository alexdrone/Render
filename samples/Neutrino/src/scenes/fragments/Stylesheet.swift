import UIKit
import RenderNeutrino

enum Palette: String, UIStylesheet {
  static var name: String = "Palette"
  case navigationBar
  case primary
  case primaryAccent
  case primaryText
  case secondary
  case accent
  case accentText
  case green
  case greenAccent
  case pink
  case pinkAccent
  case text
  case white
  case blue
}

enum Typography: String, UIStylesheet {
  static var name: String = "Typography"
  case extraSmallBold
  case small
  case smallBold
  case medium
  case mediumBold
}

