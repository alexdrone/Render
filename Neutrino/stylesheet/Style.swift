import UIKit

// MARK: - UIStylesheet

public protocol UIStyleProtocol {
  /// The full path for this style {NAMESPACE.STYLE(.MODIFIER)?}.
  var styleIdentifier: String { get }
  /// Applies this style to the view passed as argument.
  /// - note: Non KVC-compliant keys are skipped.
  func apply(to view: UIView)
}

extension UIStyleProtocol {
  /// Whether this is an instance of *UINilStyle*.
  var isNil: Bool {
    return self is UINilStyle
  }

  /// Returns the identifier for this style with the desired modifier (analogous to a pseudo
  /// selector in CSS).
  /// - note: If the condition passed as argument is false *UINilStyle* is returned.
  public func byApplyingModifier(named name: String,
                                 when condition: Bool = true) -> UIStyleProtocol {
    return condition ? "\(styleIdentifier).\(name)" : UINilStyle.nil
  }
  /// Returns this style if the conditioned passed as argument is 'true', *UINilStyle* otherwise.
  public func when(_ condition: Bool) -> UIStyleProtocol {
    return condition ? self : UINilStyle.nil
  }

  /// Returns an array with this style plus all of the modifiers that satisfy the associated
  /// conditions.
  public func withModifiers(_ modifiers: [String: Bool]) -> [UIStyleProtocol] {
    var identifiers: [UIStyleProtocol] = [self]
    for (modifier, condition) in modifiers {
      let style = self.byApplyingModifier(named: modifier, when: condition)
      if !style.isNil {
        identifiers.append(style)
      }
    }
    return identifiers
  }
}

public protocol UIStylesheet: UIStyleProtocol {
  /// The name of the stylesheet rule.
  var rawValue: String { get }
  /// The style name.
  static var styleIdentifier: String { get }
}

public extension UIStylesheet {
  /// The style name.
  public var styleIdentifier: String {
    return Self.styleIdentifier
  }
  /// Returns the rule associated to this stylesheet enum.
  public var rule: UIStylesheetRule {
    guard let rule = UIStylesheetManager.default.rule(style: Self.styleIdentifier,
                                                      name: rawValue) else {
      fatalError("Unable to resolve rule \(Self.styleIdentifier).\(rawValue).")
    }
    return rule
  }
  /// Convenience getter for *UIStylesheetRule.integer*.
  public var integer: Int {
    return rule.integer
  }
  /// Convenience getter for *UIStylesheetRule.cgFloat*.
  public var cgFloat: CGFloat {
    return rule.cgFloat
  }
  /// Convenience getter for *UIStylesheetRule.bool*.
  public var bool: Bool {
    return rule.bool
  }
  /// Convenience getter for *UIStylesheetRule.font*.
  public var font: UIFont {
    return rule.font
  }
  /// Convenience getter for *UIStylesheetRule.color*.
  public var color: UIColor {
    return rule.color
  }
  /// Convenience getter for *UIStylesheetRule.string*.
  public var string: String {
    return rule.string
  }
  /// Convenience getter for *UIStylesheetRule.object*.
  public var object: AnyObject? {
    return rule.object
  }
  /// Convenience getter for *UIStylesheetRule.enum*.
  public func `enum`<T: UIStylesheetRepresentableEnum>(_ type: T.Type,
                                                       default: T = T.init(rawValue: 0)!) -> T {
    return rule.enum(type, default: `default`)
  }

  public func apply(to view: UIView) {
    Self.apply(to: view)
  }
  /// Applies the stylesheet to the view passed as argument.
  public static func apply(to view: UIView) {
    UIStyle.apply(name: Self.styleIdentifier, to: view)
  }
}

extension String: UIStyleProtocol {
  /// The full path for the style {NAMESPACE.STYLE(.MODIFIER)?}.
  public var styleIdentifier: String {
    return self
  }
  /// Applies this style to the view passed as argument.
  public func apply(to view: UIView) {
    UIStyle.apply(name: self, to: view)
  }
}

public struct UIStyle {
  /// Applies this style to the view passed as argument.
  /// - note: Non KVC-compliant keys are skipped.
  public static func apply(name: String, to view: UIView) {
    guard let defs = UIStylesheetManager.default.defs[name] else {
      warn("Unable to resolve definition named \(name).")
      return
    }
    var bridgeDictionary: [String: Any] = [:]
    for (key, value) in defs {
      bridgeDictionary[key] = value.object
    }
    YGSet(view, bridgeDictionary, UIStylesheetManager.default.animators[name] ?? [:])
  }
  /// Returns a style identifier in the format NAMESPACE.STYLE(.MODIFIER)?.
  public static func make(_ namespace: String,
                          _ style: String,
                          _ modifier: String? = nil) -> String {
    return "\(namespace).\(style)\(modifier != nil ? ".\(modifier!)" : "")"
  }

  /// Merges the styles together and applies the to the view passed as argument.
  public static func applyStyles(_ array: [UIStyleProtocol], to view: UIView) {
    // Filters out the 'nil' styles.
    let styles = array.filter { !($0 is UINilStyle) }
    var bridgeDictionary: [String: Any] = [:]
    var bridgeTransitions: [String: UIViewPropertyAnimator] = [:]
    for style in styles {
      for (key, value) in UIStylesheetManager.default.defs[style.styleIdentifier] ?? [:] {
        bridgeDictionary[key] = value.object
      }
      for (key, value) in UIStylesheetManager.default.animators[style.styleIdentifier] ?? [:] {
        bridgeTransitions[key] = value
      }
    }
    YGSet(view, bridgeDictionary, bridgeTransitions)
  }
}

public class UINilStyle: UIStyleProtocol {
  public static let `nil` = UINilStyle()
  /// - note: 'nil' is the identifier for a *UINilStyle*.
  public var styleIdentifier: String {
    return "nil"
  }
  /// No operation.
  public func apply(to view: UIView) { }
}
