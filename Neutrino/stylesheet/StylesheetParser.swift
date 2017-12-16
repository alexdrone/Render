import Foundation

public enum ParseError: Error {
  /// Illegal format for the stylesheet.
  case malformedStylesheetStructure(message: String?)
  /// An illegal use of a '!!func' in the stylesheet.
  case illegalNumberOfArguments(function: String?)
}

public class UIStylesheetParser {
  /// The parsed *Yaml* document.
  public var defs: [String: [String: UIStylesheetRule]] = [:]

  /// Returns the rule named 'name' of a specified style.
  public func rule(style: String, name: String) -> UIStylesheetRule? {
    return defs[style]?[name]
  }

  /// Parses the markup content passed as argument.
  public func parse(yaml string: String) throws {
    let yaml = try Yaml.load(string)
    guard let root = yaml.dictionary else {
      throw ParseError.malformedStylesheetStructure(message: "The root node should be a map.")
    }
    // Parses the top level definitions.
    var yamlDefs: [String: [String: UIStylesheetRule]] = [:]
    for (key, value) in root {
      guard var defDic = value.dictionary, let defKey = key.string else {
        throw ParseError.malformedStylesheetStructure(message:"Definitions should be maps.")
      }
      // In yaml definitions can inherit from others using the <<: *ID expression. e.g.
      // myDef: &_myDef
      //   foo: 1
      // myOtherDef: &_myOtherDef
      //   <<: *_myDef
      //   bar: 2
      var defs: [String: UIStylesheetRule] = [:]
      if let inherit = defDic["<<"]?.dictionary {
        for (ik, iv) in inherit {
          guard let isk = ik.string else {
            throw ParseError.malformedStylesheetStructure(message: "Invalid rule key.")
          }
          defs[isk] = try UIStylesheetRule(key: isk, value: iv)
        }
      }
      for (k, v) in defDic {
        guard let sk = k.string, sk != "<<" else { continue }
        defs[sk] = try UIStylesheetRule(key: sk, value: v)
      }
      yamlDefs[defKey] = defs
    }
    self.defs = yamlDefs
  }
}

/// Represents a rule for a style definition.
public class UIStylesheetRule: CustomStringConvertible {
  enum ValueType: String {
    case expression
    case bool
    case number
    case string
    case font
    case color
    case undefined
  }
  private typealias ConditionalStoreType = [(Expression, Any?)]

  /// The key for this value.
  var key: String
  /// The value type.
  var type: ValueType!
  /// The computed value.
  var store: Any?
  /// Whether ther store is of type [(Expression, Any?)].
  var isConditional: Bool = false

  init(key: String, value: Yaml) throws {
    self.key = key
    let (type, store, isConditional) = try parseValue(for: value)
    (self.type, self.store, self.isConditional) = (type, store, isConditional)
  }

  public var integer: Int {
    return (nsNumber as? Int) ?? 0
  }

  public var cgFloat: CGFloat {
    return (nsNumber as? CGFloat) ?? 0
  }

  public var bool: Bool {
    return (nsNumber as? Bool) ?? false
  }

  public var font: UIFont {
    return castType(type: .font, default: UIFont.init())
  }

  public var color: UIColor {
    return castType(type: .color, default: UIColor.init())
  }

  public var string: String {
    return castType(type: .string, default: String.init())
  }

  private func castType<T>(type: ValueType, default: T) -> T {
    guard self.type == type else { return `default` }
    if isConditional { return evaluateConditional(variable: self.store, default: `default`) }
    if let value = self.store as? T { return value }
    return `default`
  }

  private func evaluateConditional<T>(variable: Any?, default: T) -> T {
    if let store = variable as? ConditionalStoreType {
      for entry in store.map({ ($0.0, $0.1 as? T) }) {
        guard let value = entry.1 else { continue }
        if let result = try? entry.0.evaluate(), result > 0 {
          return value
        }
      }
    }
    return `default`
  }

  static private let defaultExpression = Expression("0")
  public var nsNumber: NSNumber {
    if type == .expression {
      let expression = castType(type: .expression, default: UIStylesheetRule.defaultExpression)
      let double = (try? expression.evaluate()) ?? 0
      return NSNumber(value: double)
    }
    if type == .bool || type == .number, let nsNumber = store as? NSNumber {
      return nsNumber
    }
    return NSNumber(value: 0)
  }

  /// Parse the rhs value of a rule.
  private func parseValue(for yaml: Yaml) throws -> (ValueType, Any?, Bool) {
    switch yaml {
    case .bool(let v): return(.bool, v, false)
    case .double(let v): return (.number, v, false)
    case .int(let v): return (.number, v, false)
    case .string(let v):
      let result = try parse(string: v)
      return (result.0, result.1, false)
    case .dictionary(let v):
      let result = try parse(conditionalDictionary: v)
      return (result.0, result.1, true)
    default: return (.undefined, nil, false)
    }
  }

  /// Parse a map value.
  /// - Note: The lhs is an expression and the rhs a value. 'default' is a tautology.
  private func parse(conditionalDictionary: [Yaml: Yaml]) throws -> (ValueType, Any?) {
    var types: [ValueType] = []
    var result: ConditionalStoreType = []
    for (key, yaml) in conditionalDictionary {
      guard let string = key.string, let expression = parseExpression(string) else {
        throw ParseError.malformedStylesheetStructure(message: "\(key) is not a valid expression.")
      }
      let value = try parseValue(for: yaml)
      let tuple = (UIStylesheetExpression.builder(expression), value.1)
      types.append(value.0)
      if string.contains("default") {
        result.append(tuple)
      } else {
        result.insert(tuple, at: 0)
      }
    }
    return (types.first ?? .undefined, result)
  }

  /// Parse a string value.
  /// - Note: This could be an expression (e.g. "${1==1}"), a function (e.g. "!!font(Arial, 42)")
  /// or a simple string.
  private func parse(string: String) throws -> (ValueType, Any?) {
    struct Token {
      static let functionBrackets = ("(", ")")
      static let functionDelimiters = (",")
      static let fontFunction = "!!font"
      static let sizeFunction = "!!size"
      static let colorFunction = "!!color"
    }
    func expression(from string: String) -> Expression? {
      if let exprString = parseExpression(string) {
        return UIStylesheetExpression.builder(exprString)
      }
      return nil
    }
    // Returns the arguments of the function 'function' as an array of strings.
    func arguments(for function: String) -> [String] {
      let substring = string
        .replacingOccurrences(of: function, with: "")
        .replacingOccurrences(of: Token.functionBrackets.0, with: "")
        .replacingOccurrences(of: Token.functionBrackets.1, with: "")
      return substring.components(separatedBy: Token.functionDelimiters)
    }
    // Numbers are boxed as NSNumber.
    func parse(numberFromString string: String) -> NSNumber {
      if let expr = expression(from: string) {
        return NSNumber(value: (try? expr.evaluate()) ?? 0)
      } else {
        return NSNumber(value: (string as NSString).doubleValue)
      }
    }
    // !!expression
    if let expression = expression(from: string) {
      return (.expression, expression)
    }
    // !!font
    if string.hasPrefix(Token.fontFunction) {
      let args = arguments(for: Token.fontFunction)
      guard args.count == 2 else {
        throw ParseError.illegalNumberOfArguments(function: Token.fontFunction)
      }
      let size: CGFloat = CGFloat(parse(numberFromString: args[1]).floatValue)
      return (.font, args[0] == "system" ?
        UIFont.systemFont(ofSize: size) : UIFont(name:  args[0], size: size))
    }
    // !!color
    if string.hasPrefix(Token.colorFunction) {
      let args = arguments(for: Token.colorFunction)
      guard args.count == 1 else {
        throw ParseError.illegalNumberOfArguments(function: Token.colorFunction)
      }
      return (.color, UIColor(hex: args[0]) ?? .black)
    }
    // !!str
    return (.string, string)
  }

  /// Parse an expression.
  /// - Note: The expression delimiters is ${EXPR}.
  private func parseExpression(_ string: String) -> String? {
    struct Token {
      static let expression = "$"
      static let expressionBrackets = ("{", "}")
    }
    guard string.hasPrefix(Token.expression) else { return nil }
    let substring = string
      .replacingOccurrences(of: Token.expression, with: "")
      .replacingOccurrences(of: Token.expressionBrackets.0, with: "")
      .replacingOccurrences(of: Token.expressionBrackets.1, with: "")
    return substring
  }

  /// A textual representation of this instance.
  public var description: String {
    return type.rawValue
  }
}

// MARK: Expression Constants

struct UIStylesheetExpression {

  private static let constants: [String: Double] = [
    // Idiom.
    "iPhoneSE": Double(UIScreenStateFactory.Idiom.iPhoneSE.rawValue),
    "iPhone8": Double(UIScreenStateFactory.Idiom.iPhone8.rawValue),
    "iPhone8Plus": Double(UIScreenStateFactory.Idiom.iPhone8Plus.rawValue),
    "iPhoneX": Double(UIScreenStateFactory.Idiom.iPhoneX.rawValue),
    "iPad": Double(UIScreenStateFactory.Idiom.iPad.rawValue),
    "tv": Double(UIScreenStateFactory.Idiom.tv.rawValue),
    // Bounds.
    "iPhoneSE.height": Double(568),
    "iPhone8.height": Double(667),
    "iPhone8Plus.height": Double(736),
    "iPhoneX.height": Double(812),
    "iPhoneSE.width": Double(320),
    "iPhone8.width": Double(375),
    "iPhone8Plus.width": Double(414),
    "iPhoneX.width": Double(375),
    // Orientation and Size Classes.
    "Orientation.portait": Double(UIScreenStateFactory.Orientation.portrait.rawValue),
    "Orientation.landscape": Double(UIScreenStateFactory.Orientation.portrait.rawValue),
    "SizeClass.compact": Double(UIScreenStateFactory.SizeClass.compact.rawValue),
    "SizeClass.regular": Double(UIScreenStateFactory.SizeClass.regular.rawValue),
    "SizeClass.unspecified": Double(UIScreenStateFactory.SizeClass.unspecified.rawValue),
    // Yoga.
    "inherit": Double(0),
    "ltr": Double(1),
    "rtl": Double(2),
    "auto": Double(0),
    "flexStart": Double(1),
    "center": Double(2),
    "flexEnd": Double(3),
    "stretch": Double(4),
    "baseline": Double(5),
    "spaceBetween": Double(6),
    "spaceAround": Double(7),
    "flex": Double(0),
    "none": Double(1),
    "column": Double(0),
    "columnReverse": Double(1),
    "row": Double(2),
    "rowReverse": Double(3),
    "visible": Double(0),
    "hidden": Double(1),
    "absolute": Double(2),
    "noWrap": Double(0),
    "wrap": Double(1),
    "wrapReverse": Double(2),
    // Font Weigths.
    "FontWeight.ultralight": Double(-0.800000011920929),
    "FontWeight.thin": Double(-0.600000023841858),
    "FontWeight.light": Double(-0.400000005960464),
    "FontWeight.regular": Double(0),
    "FontWeight.medium": Double(0.230000004172325),
    "FontWeight.semibold": Double(0.300000011920929),
    "FontWeight.bold": Double(0.400000005960464),
    "FontWeight.heavy": Double(0.560000002384186),
    "FontWeight.black": Double(0.620000004768372),
    // Text Alignment.
    "TextAlignment.left": Double(0),
    "TextAlignment.center": Double(1),
    "TextAlignment.right": Double(2),
    "TextAlignment.justified": Double(3),
    "TextAlignment.natural": Double(4),
    // Line Break Mode.
    "LineBreakMode.byWordWrapping": Double(0),
    "LineBreakMode.byCharWrapping": Double(1),
    "LineBreakMode.byClipping": Double(2),
    "LineBreakMode.byTruncatingHead": Double(3),
    "LineBreakMode.byTruncatingMiddle": Double(4),
    // Image Orientation.
    "ImageOrientation.up": Double(0),
    "ImageOrientation.down": Double(1),
    "ImageOrientation.left": Double(2),
    "ImageOrientation.right": Double(3),
    "ImageOrientation.upMirrored": Double(4),
    "ImageOrientation.downMirrored": Double(5),
    "ImageOrientation.leftMirrored": Double(6),
    "ImageOrientation.rightMirrored": Double(7),
    // Image Resizing Mode.
    "ImageResizingMode.title": Double(0),
    "ImageResizingMode.stretch": Double(1),
  ]

  private static let symbols: [Expression.Symbol: Expression.Symbol.Evaluator] = [
    .variable("idiom"): { _ in
      Double(UIScreenStateFactory.default.state().idiom.rawValue) },
    .variable("orientation"): { _ in
      Double(UIScreenStateFactory.default.state().orientation.rawValue) },
    .variable("verticalSizeClass"): { _ in
      Double(UIScreenStateFactory.default.state().verticalSizeClass.rawValue) },
    .variable("horizontalSizeClass"): { _ in
      Double(UIScreenStateFactory.default.state().verticalSizeClass.rawValue) },
    ]

  /// The default *Expression* builder function.
  static func builder(_ string: String) -> Expression {
    return Expression(string,
                      options: [Expression.Options.boolSymbols, Expression.Options.pureSymbols],
                      constants: UIStylesheetExpression.constants,
                      symbols: UIStylesheetExpression.symbols)
  }
}
