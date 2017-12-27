import UIKit
import RenderNeutrino

enum Palette: String, UIStylesheet {
  static var styleIdentifier: String = "Palette"
  case primary
  case primaryAccent
  case primaryText
  case secondary
  case accent
  case accentText
  case text
  case white
}

enum Typography: String, UIStylesheet {
  static var styleIdentifier: String = "Typography"
  case extraSmallBold
  case small
  case smallBold
  case medium
  case mediumBold
}

enum Margin: String, UIStylesheet {
  static var styleIdentifier: String = "Margin"
  case xsmall
  case small
  case medium
  case large
}

enum FacebookPalette: String, UIStylesheet {
  static var styleIdentifier: String = "FacebookPalette"
  case white
  case blue
  case lightGray
  case gray
  case black
}

enum FacebookTypography: String, UIStylesheet {
  static var styleIdentifier: String = "FacebookTypography"
  case title
  case caption
  case text
  case button
  case small
}
