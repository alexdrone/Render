import UIKit

//
public let defaultContext: UIContext = UIContext()

public protocol UIStylesheetObject {
  /// The name of the stylesheet varible defined in 'stylesheet.js'.
  var rawValue: String { get }
}

/// The enum that represents the palette used across the app.
public protocol UIStylesheetPalette: UIStylesheetObject { }

extension UIStylesheetPalette {
  /// The *UIColor* generated from this stylesheet value.
  public var color: UIColor {
    return UIContext.default.jsBridge.variable(namespace: .palette, name: rawValue) ?? .black
  }
}

/// The enum that represents the fonts used across the app.
public protocol UIStylesheetTypography: UIStylesheetObject { }

extension UIStylesheetTypography {
  /// The *UIFont* generated from this stylesheet value.
  public var font: UIFont {
    return UIContext.default.jsBridge.variable(namespace: .typography, name: rawValue) ?? UIFont()
  }
}

/// The enum that represents general app configuration flags.
public protocol UIStylesheetFlags: UIStylesheetObject { }

extension UIStylesheetFlags {
  /// The boolean flat generated from this stylesheet value.
  public var flag: Bool {
    return UIContext.default.jsBridge.variable(namespace: .flags, name: rawValue) ?? false
  }
}

/// The enum that represents layout constants.
public protocol UIStylesheetConstants: UIStylesheetObject { }

extension UIStylesheetConstants {
  /// The layout constant generated from this stylesheet value.
  public var flag: CGFloat {
    return UIContext.default.jsBridge.variable(namespace: .constants, name: rawValue) ?? 0
  }
}
