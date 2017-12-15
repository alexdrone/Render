import Foundation

public enum ParseError: Error {
  /// Illegal format for the stylesheet.
  case malformedStylesheetStructure(message: String?)
  ///
  case illegalNumberOfArguments(function: String?)
}

public class UIStylesheetParser {
  /// The parsed *Yaml* document.
  public var yaml: Yaml?

  /// Parses the markup content passed as argument.
  public func parse(yaml string: String) throws {
    yaml = try Yaml.load(string)
    guard let root = yaml?.dictionary else {
      throw ParseError.malformedStylesheetStructure(message: "The root node should be a map.")
    }
    // Parses the top level definitions.
    var yamlDefs: [String: [String: UIStylesheetRule]] = [:]
    for (key, value) in root {
      guard var defDic = value.dictionary, let defKey = key.string else {
        throw ParseError.malformedStylesheetStructure(message:
          "Every top level namespace should be a map.")
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

    print(yamlDefs)
  }
}

/// Represents a rule for a style definition.
class UIStylesheetRule: CustomStringConvertible {
  enum ValueType: String {
    case expression
    case bool
    case number
    case string
    case font
    case color
    case undefined
  }
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
    var result: [(Expression, Any?)] = []
    for (key, yaml) in conditionalDictionary {
      guard let string = key.string, let expression = parseExpression(string) else {
        throw ParseError.malformedStylesheetStructure(message: "\(key) is not a valid expression.")
      }
      let value = try parseValue(for: yaml)
      let tuple = (UIStylesheetExpressionBuilder(expression), value.1)
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
        return UIStylesheetExpressionBuilder(exprString)
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
  var description: String {
    return type.rawValue
  }
}

/// The default *Expression* builder function.
func UIStylesheetExpressionBuilder(_ string: String) -> Expression {
  return Expression(string)
}
