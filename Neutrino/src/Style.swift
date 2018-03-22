import UIKit

// MARK: - UIStyle

open class UIStyle: UIStyleProtocol {
  static var notApplicableStyleIdentifier: String = "__UIStyleNotApplicableStyleIdentifier"
  public let styleIdentifier: String = UIStyle.notApplicableStyleIdentifier

  /// Applies the style to the view passed as argument.
  public func apply(to view: UIView) { }
}

// MARK: - UIStyleProtocol

public protocol UIStyleProtocol {
  /// The full path for this style {NAMESPACE.STYLE(.MODIFIER)?}.
  /// - note: Not necessary for *UIStyle* subclasses.
  var styleIdentifier: String { get }
  /// Applies this style to the view passed as argument.
  /// - note: Non KVC-compliant keys are skipped if this is a style generated from a stylesheet.
  func apply(to view: UIView)
}

public class UINilStyle: UIStyle {
  public static let `nil` = UINilStyle()
  /// No operation.
  public override func apply(to view: UIView) { }
}
