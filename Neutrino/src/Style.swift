import UIKit

public protocol UIStylesheetObject {
  /// The name of the stylesheet varible defined in 'stylesheet.js'.
  var rawValue: String { get }
}

public class UIStylesheet {
  /// The context owning this stylesheet.
  private weak var context: UIContext?

  init(context: UIContext) {
    self.context = context
  }

  public func palette<T: UIStylesheetPalette>(_ variable: T) -> UIColor {
    return context?.jsBridge.variable(namespace: .palette, name: variable.rawValue) ?? .black
  }

  public func typography<T: UIStylesheetTypography>(_ variable: T) -> UIFont {
    return context?.jsBridge.variable(namespace: .typography, name: variable.rawValue) ?? UIFont()
  }

  public func flag<T: UIStylesheetFlags>(_ variable: T) -> Bool {
    return context?.jsBridge.variable(namespace: .flags, name: variable.rawValue) ?? false
  }

  public func constant<T: UIStylesheetConstants>(_ variable: T) -> CGFloat {
    return context?.jsBridge.variable(namespace: .constants, name: variable.rawValue) ?? 0
  }
}

/// The enum that represents the palette used across the app.
public protocol UIStylesheetPalette: UIStylesheetObject { }
/// The enum that represents the fonts used across the app.
public protocol UIStylesheetTypography: UIStylesheetObject { }
/// The enum that represents general app configuration flags.
public protocol UIStylesheetFlags: UIStylesheetObject { }
/// The enum that represents layout constants.
public protocol UIStylesheetConstants: UIStylesheetObject { }
