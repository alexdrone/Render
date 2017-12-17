// The MIT License (MIT)
//
// Copyright (c) 2015 Behrang Noruzi Niya
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Get the latest at https://github.com/behrang/YamlSwift

import Foundation

infix operator |>: Functional
func |> <T, U> (x: T, f: (T) -> U) -> U {
  return f(x)
}

extension Yaml {
  enum TokenType: Swift.String {
    case yamlDirective = "%YAML"
    case docStart = "doc-start"
    case docend = "doc-end"
    case comment = "comment"
    case space = "space"
    case newLine = "newline"
    case indent = "indent"
    case dedent = "dedent"
    case null = "null"
    case _true = "true"
    case _false = "false"
    case infinityP = "+infinity"
    case infinityN = "-infinity"
    case nan = "nan"
    case double = "double"
    case int = "int"
    case intOct = "int-oct"
    case intHex = "int-hex"
    case intSex = "int-sex"
    case anchor = "&"
    case alias = "*"
    case comma = ","
    case openSB = "["
    case closeSB = "]"
    case dash = "-"
    case openCB = "{"
    case closeCB = "}"
    case key = "key"
    case keyDQ = "key-dq"
    case keySQ = "key-sq"
    case questionMark = "?"
    case colonFO = ":-flow-out"
    case colonFI = ":-flow-in"
    case colon = ":"
    case literal = "|"
    case folded = ">"
    case reserved = "reserved"
    case stringDQ = "string-dq"
    case stringSQ = "string-sq"
    case stringFI = "string-flow-in"
    case stringFO = "string-flow-out"
    case string = "string"
    case end = "end"
  }
}

private typealias TokenPattern = (type: Yaml.TokenType, pattern: NSRegularExpression)

extension Yaml {
  typealias TokenMatch = (type: Yaml.TokenType, match: String)
}

private let bBreak = "(?:\\r\\n|\\r|\\n)"

// printable non-space chars,
// except `:`(3a), `#`(23), `,`(2c), `[`(5b), `]`(5d), `{`(7b), `}`(7d)
private let safeIn = "\\x21\\x22\\x24-\\x2b\\x2d-\\x39\\x3b-\\x5a\\x5c\\x5e-\\x7a" +
  "\\x7c\\x7e\\x85\\xa0-\\ud7ff\\ue000-\\ufefe\\uff00\\ufffd" +
"\\U00010000-\\U0010ffff"
// with flow indicators: `,`, `[`, `]`, `{`, `}`
private let safeOut = "\\x2c\\x5b\\x5d\\x7b\\x7d" + safeIn
private let plainOutPattern =
"([\(safeOut)]#|:(?![ \\t]|\(bBreak))|[\(safeOut)]|[ \\t])+"
private let plainInPattern =
"([\(safeIn)]#|:(?![ \\t]|\(bBreak))|[\(safeIn)]|[ \\t]|\(bBreak))+"
private let dashPattern = Yaml.Regex.regex("^-([ \\t]+(?!#|\(bBreak))|(?=[ \\t\\n]))")
private let finish = "(?= *(,|\\]|\\}|( #.*)?(\(bBreak)|$)))"

private let tokenPatterns: [TokenPattern] = [
  (.yamlDirective, Yaml.Regex.regex("^%YAML(?= )")),
  (.docStart, Yaml.Regex.regex("^---")),
  (.docend, Yaml.Regex.regex("^\\.\\.\\.")),
  (.comment, Yaml.Regex.regex("^#.*|^\(bBreak) *(#.*)?(?=\(bBreak)|$)")),
  (.space, Yaml.Regex.regex("^ +")),
  (.newLine, Yaml.Regex.regex("^\(bBreak) *")),
  (.dash, dashPattern!),
  (.null, Yaml.Regex.regex("^(null|Null|NULL|~)\(finish)")),
  (._true, Yaml.Regex.regex("^(true|True|TRUE)\(finish)")),
  (._false, Yaml.Regex.regex("^(false|False|FALSE)\(finish)")),
  (.infinityP, Yaml.Regex.regex("^\\+?\\.(inf|Inf|INF)\(finish)")),
  (.infinityN, Yaml.Regex.regex("^-\\.(inf|Inf|INF)\(finish)")),
  (.nan, Yaml.Regex.regex("^\\.(nan|NaN|NAN)\(finish)")),
  (.int, Yaml.Regex.regex("^[-+]?[0-9]+\(finish)")),
  (.intOct, Yaml.Regex.regex("^0o[0-7]+\(finish)")),
  (.intHex, Yaml.Regex.regex("^0x[0-9a-fA-F]+\(finish)")),
  (.intSex, Yaml.Regex.regex("^[0-9]{2}(:[0-9]{2})+\(finish)")),
  (.double, Yaml.Regex.regex("^[-+]?(\\.[0-9]+|[0-9]+(\\.[0-9]*)?)([eE][-+]?[0-9]+)?\(finish)")),
  (.anchor, Yaml.Regex.regex("^&\\w+")),
  (.alias, Yaml.Regex.regex("^\\*\\w+")),
  (.comma, Yaml.Regex.regex("^,")),
  (.openSB, Yaml.Regex.regex("^\\[")),
  (.closeSB, Yaml.Regex.regex("^\\]")),
  (.openCB, Yaml.Regex.regex("^\\{")),
  (.closeCB, Yaml.Regex.regex("^\\}")),
  (.questionMark, Yaml.Regex.regex("^\\?( +|(?=\(bBreak)))")),
  (.colonFO, Yaml.Regex.regex("^:(?!:)")),
  (.colonFI, Yaml.Regex.regex("^:(?!:)")),
  (.literal, Yaml.Regex.regex("^\\|.*")),
  (.folded, Yaml.Regex.regex("^>.*")),
  (.reserved, Yaml.Regex.regex("^[@`]")),
  (.stringDQ, Yaml.Regex.regex("^\"([^\\\\\"]|\\\\(.|\(bBreak)))*\"")),
  (.stringSQ, Yaml.Regex.regex("^'([^']|'')*'")),
  (.stringFO, Yaml.Regex.regex("^\(plainOutPattern)(?=:([ \\t]|\(bBreak))|\(bBreak)|$)")),
  (.stringFI, Yaml.Regex.regex("^\(plainInPattern)")),
]

extension Yaml {
  static func escapeErrorContext (_ text: String) -> String {
    let endIndex = text.index(text.startIndex,
                              offsetBy: 50,
                              limitedBy: text.endIndex) ?? text.endIndex
    let escaped = text.substring(to: endIndex)
      |> Yaml.Regex.replace(Yaml.Regex.regex("\\r"), template: "\\\\r")
      |> Yaml.Regex.replace(Yaml.Regex.regex("\\n"), template: "\\\\n")
      |> Yaml.Regex.replace(Yaml.Regex.regex("\""), template: "\\\\\"")
    return "near \"\(escaped)\""
  }


  static func tokenize (_ text: String) -> YAMLResult<[TokenMatch]> {
    var text = text
    var matchList: [TokenMatch] = []
    var indents = [0]
    var insideFlow = 0
    next:
      while text.endIndex > text.startIndex {
        for tokenPattern in tokenPatterns {
          let range = Yaml.Regex.matchRange(text, regex: tokenPattern.pattern)
          if range.location != NSNotFound {
            let rangeend = range.location + range.length
            switch tokenPattern.type {

            case .newLine:
              let match = text |> Yaml.Regex.substringWithRange(range)
              let lastindent = indents.last ?? 0
              let rest = match.substring(from: match.index(after: match.startIndex))
              let spaces = rest.characters.count
              let nestedBlockSequence =
                Yaml.Regex.matches(text |> Yaml.Regex.substringFromIndex(rangeend),
                                   regex: dashPattern!)
              if spaces == lastindent {
                matchList.append(TokenMatch(.newLine, match))
              } else if spaces > lastindent {
                if insideFlow == 0 {
                  if matchList.last != nil &&
                    matchList[matchList.endIndex - 1].type == .indent {
                    indents[indents.endIndex - 1] = spaces
                    matchList[matchList.endIndex - 1] = TokenMatch(.indent, match)
                  } else {
                    indents.append(spaces)
                    matchList.append(TokenMatch(.indent, match))
                  }
                }
              } else if nestedBlockSequence && spaces == lastindent - 1 {
                matchList.append(TokenMatch(.newLine, match))
              } else {
                while nestedBlockSequence && spaces < (indents.last ?? 0) - 1
                  || !nestedBlockSequence && spaces < indents.last ?? 0 {
                    indents.removeLast()
                    matchList.append(TokenMatch(.dedent, ""))
                }
                matchList.append(TokenMatch(.newLine, match))
              }

            case .dash, .questionMark:
              let match = text |> Yaml.Regex.substringWithRange(range)
              let index = match.index(after: match.startIndex)
              let indent = match.count
              indents.append((indents.last ?? 0) + indent)
              matchList.append(
                TokenMatch(tokenPattern.type, match.substring(to: index)))
              matchList.append(TokenMatch(.indent, match.substring(from: index)))

            case .colonFO:
              if insideFlow > 0 {
                continue
              }
              fallthrough

            case .colonFI:
              let match = text |> Yaml.Regex.substringWithRange(range)
              matchList.append(TokenMatch(.colon, match))
              if insideFlow == 0 {
                indents.append((indents.last ?? 0) + 1)
                matchList.append(TokenMatch(.indent, ""))
              }

            case .openSB, .openCB:
              insideFlow += 1
              matchList.append(
                TokenMatch(tokenPattern.type, text |> Yaml.Regex.substringWithRange(range)))

            case .closeSB, .closeCB:
              insideFlow -= 1
              matchList.append(
                TokenMatch(tokenPattern.type, text |> Yaml.Regex.substringWithRange(range)))

            case .literal, .folded:
              matchList.append(
                TokenMatch(tokenPattern.type, text |> Yaml.Regex.substringWithRange(range)))
              text = text |> Yaml.Regex.substringFromIndex(rangeend)
              let lastindent = indents.last ?? 0
              let minindent = 1 + lastindent
              let blockPattern = Yaml.Regex.regex(("^(\(bBreak) *)*(\(bBreak)" +
                "( {\(minindent),})[^ ].*(\(bBreak)( *|\\3.*))*)(?=\(bBreak)|$)"))
              let (lead, rest) = text |> Yaml.Regex.splitLead(blockPattern!)
              text = rest
              let block = (lead
                |> Yaml.Regex.replace(Yaml.Regex.regex("^\(bBreak)"), template: "")
                |> Yaml.Regex.replace(Yaml.Regex.regex("^ {0,\(lastindent)}"), template: "")
                |> Yaml.Regex.replace(Yaml.Regex.regex("\(bBreak) {0,\(lastindent)}"), template: "\n")
                ) + (Yaml.Regex.matches(text, regex: Yaml.Regex.regex("^\(bBreak)"))
                  && lead.endIndex > lead.startIndex
                  ? "\n" : "")
              matchList.append(TokenMatch(.string, block))
              continue next

            case .stringFO:
              if insideFlow > 0 {
                continue
              }
              let indent = (indents.last ?? 0)
              let blockPattern = Yaml.Regex.regex(("^\(bBreak)( *| {\(indent),}" +
                "\(plainOutPattern))(?=\(bBreak)|$)"))
              var block = text
                |> Yaml.Regex.substringWithRange(range)
                |> Yaml.Regex.replace(Yaml.Regex.regex("^[ \\t]+|[ \\t]+$"), template: "")
              text = text |> Yaml.Regex.substringFromIndex(rangeend)
              while true {
                let range = Yaml.Regex.matchRange(text, regex: blockPattern!)
                if range.location == NSNotFound {
                  break
                }
                let s = text |> Yaml.Regex.substringWithRange(range)
                block += "\n" +
                  Yaml.Regex.replace(
                    Yaml.Regex.regex("^\(bBreak)[ \\t]*|[ \\t]+$"), template: "")(s)
                text = text |> Yaml.Regex.substringFromIndex(range.location + range.length)
              }
              matchList.append(TokenMatch(.string, block))
              continue next

            case .stringFI:
              let match = text
                |> Yaml.Regex.substringWithRange(range)
                |> Yaml.Regex.replace(Yaml.Regex.regex("^[ \\t]|[ \\t]$"), template: "")
              matchList.append(TokenMatch(.string, match))

            case .reserved:
              return fail(escapeErrorContext(text))

            default:
              matchList.append(TokenMatch(tokenPattern.type, text |>
                Yaml.Regex.substringWithRange(range)))
            }
            text = text |> Yaml.Regex.substringFromIndex(rangeend)
            continue next
          }
        }
        return fail(escapeErrorContext(text))
    }
    while indents.count > 1 {
      indents.removeLast()
      matchList.append((.dedent, ""))
    }
    matchList.append((.end, ""))
    return lift(matchList)
  }
}

import Foundation

public enum Yaml {
  case null
  case bool(Swift.Bool)
  case int(Swift.Int)
  case double(Swift.Double)
  case string(Swift.String)
  case array([Yaml])
  case dictionary([Yaml: Yaml])

  static public func == (lhs: Yaml, rhs: Yaml) -> Bool {
    switch (lhs, rhs) {
    case (.null, .null):
      return true
    case (.bool(let lv), .bool(let rv)):
      return lv == rv
    case (.int(let lv), .int(let rv)):
      return lv == rv
    case (.int(let lv), .double(let rv)):
      return Double(lv) == rv
    case (.double(let lv), .double(let rv)):
      return lv == rv
    case (.double(let lv), .int(let rv)):
      return lv == Double(rv)
    case (.string(let lv), .string(let rv)):
      return lv == rv
    case (.array(let lv), .array(let rv)):
      return lv == rv
    case (.dictionary(let lv), .dictionary(let rv)):
      return lv == rv
    default:
      return false
    }
  }

  // unary `-` operator
  static public prefix func - (value: Yaml) -> Yaml {
    switch value {
    case .int(let v):
      return .int(-v)
    case .double(let v):
      return .double(-v)
    default:
      fatalError("`-` operator may only be used on .int or .double Yaml values")
    }
  }
}

extension Yaml {
  public enum ResultError: Error {
    case message(String?)
  }
}

extension Yaml: ExpressibleByNilLiteral {
  public init(nilLiteral: ()) {
    self = .null
  }
}

extension Yaml: ExpressibleByBooleanLiteral {
  public init(booleanLiteral: BooleanLiteralType) {
    self = .bool(booleanLiteral)
  }
}

extension Yaml: ExpressibleByIntegerLiteral {
  public init(integerLiteral: IntegerLiteralType) {
    self = .int(integerLiteral)
  }
}

extension Yaml: ExpressibleByFloatLiteral {
  public init(floatLiteral: FloatLiteralType) {
    self = .double(floatLiteral)
  }
}

extension Yaml: ExpressibleByStringLiteral {
  public init(stringLiteral: StringLiteralType) {
    self = .string(stringLiteral)
  }

  public init(extendedGraphemeClusterLiteral: StringLiteralType) {
    self = .string(extendedGraphemeClusterLiteral)
  }

  public init(unicodeScalarLiteral: StringLiteralType) {
    self = .string(unicodeScalarLiteral)
  }
}

extension Yaml: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Yaml...) {
    self = .array(elements)
  }
}

extension Yaml: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (Yaml, Yaml)...) {
    var dictionary = [Yaml: Yaml]()
    for (k, v) in elements {
      dictionary[k] = v
    }
    self = .dictionary(dictionary)
  }
}

extension Yaml: CustomStringConvertible {
  public var description: Swift.String {
    switch self {
    case .null:
      return "Null"
    case .bool(let b):
      return "Bool(\(b))"
    case .int(let i):
      return "Int(\(i))"
    case .double(let f):
      return "Double(\(f))"
    case .string(let s):
      return "String(\(s))"
    case .array(let s):
      return "Array(\(s))"
    case .dictionary(let m):
      return "Dictionary(\(m))"
    }
  }
}

extension Yaml: Hashable {
  public var hashValue: Swift.Int {
    return description.hashValue
  }
}



extension Yaml {

  public static func load (_ text: Swift.String) throws -> Yaml {
    let result = tokenize(text) >>=- Context.parseDoc
    if let value = result.value { return value } else { throw ResultError.message(result.error) }
  }

  public static func loadMultiple (_ text: Swift.String) throws -> [Yaml] {
    let result = tokenize(text) >>=- Context.parseDocs
    if let value = result.value { return value } else { throw ResultError.message(result.error) }

  }

  public static func debug (_ text: Swift.String) -> Yaml? {
    let result = tokenize(text)
      >>- { tokens in print("\n====== Tokens:\n\(tokens)"); return tokens }
      >>=- Context.parseDoc
      >>- { value -> Yaml in print("------ Doc:\n\(value)"); return value }
    if let error = result.error {
      print("~~~~~~\n\(error)")
    }
    return result.value
  }

  public static func debugMultiple (_ text: Swift.String) -> [Yaml]? {
    let result = tokenize(text)
      >>- { tokens in print("\n====== Tokens:\n\(tokens)"); return tokens }
      >>=- Context.parseDocs
      >>- { values -> [Yaml] in values.forEach {
        v in print("------ Doc:\n\(v)")
        }; return values }
    if let error = result.error {
      print("~~~~~~\n\(error)")
    }
    return result.value
  }
}

extension Yaml {
  public subscript(index: Swift.Int) -> Yaml {
    get {
      assert(index >= 0)
      switch self {
      case .array(let array):
        if array.indices.contains(index) {
          return array[index]
        } else {
          return .null
        }
      default:
        return .null
      }
    }
    set {
      assert(index >= 0)
      switch self {
      case .array(let array):
        let emptyCount = max(0, index + 1 - array.count)
        let empty = [Yaml](repeating: .null, count: emptyCount)
        var new = array
        new.append(contentsOf: empty)
        new[index] = newValue
        self = .array(new)
      default:
        var array = [Yaml](repeating: .null, count: index + 1)
        array[index] = newValue
        self = .array(array)
      }
    }
  }

  public subscript(key: Yaml) -> Yaml {
    get {
      switch self {
      case .dictionary(let dictionary):
        return dictionary[key] ?? .null
      default:
        return .null
      }
    }
    set {
      switch self {
      case .dictionary(let dictionary):
        var new = dictionary
        new[key] = newValue
        self = .dictionary(new)
      default:
        var dictionary = [Yaml: Yaml]()
        dictionary[key] = newValue
        self = .dictionary(dictionary)
      }
    }
  }
}

extension Yaml {
  public var bool: Swift.Bool? {
    switch self {
    case .bool(let b):
      return b
    default:
      return nil
    }
  }

  public var int: Swift.Int? {
    switch self {
    case .int(let i):
      return i
    case .double(let f):
      if Swift.Double(Swift.Int(f)) == f {
        return Swift.Int(f)
      } else {
        return nil
      }
    default:
      return nil
    }
  }

  public var double: Swift.Double? {
    switch self {
    case .double(let f):
      return f
    case .int(let i):
      return Swift.Double(i)
    default:
      return nil
    }
  }

  public var string: Swift.String? {
    switch self {
    case .string(let s):
      return s
    default:
      return nil
    }
  }

  public var array: [Yaml]? {
    switch self {
    case .array(let array):
      return array
    default:
      return nil
    }
  }

  public var dictionary: [Yaml: Yaml]? {
    switch self {
    case .dictionary(let dictionary):
      return dictionary
    default:
      return nil
    }
  }

  public var count: Swift.Int? {
    switch self {
    case .array(let array):
      return array.count
    case .dictionary(let dictionary):
      return dictionary.count
    default:
      return nil
    }
  }
}

internal enum YAMLResult<T> {
  case error(String)
  case value(T)

  public var error: String? {
    switch self {
    case .error(let e): return e
    case .value: return nil
    }
  }

  public var value: T? {
    switch self {
    case .error: return nil
    case .value(let v): return v
    }
  }

  public func map <U> (f: (T) -> U) -> YAMLResult<U> {
    switch self {
    case .error(let e): return .error(e)
    case .value(let v): return .value(f(v))
    }
  }

  public func flatMap <U> (f: (T) -> YAMLResult<U>) -> YAMLResult<U> {
    switch self {
    case .error(let e): return .error(e)
    case .value(let v): return f(v)
    }
  }
}

precedencegroup Functional {
  associativity: left
  higherThan: DefaultPrecedence
}

infix operator <*>: Functional
func <*> <T, U> (f: YAMLResult<(T) -> U>, x: YAMLResult<T>) -> YAMLResult<U> {
  switch (x, f) {
  case (.error(let e), _): return .error(e)
  case (.value, .error(let e)): return .error(e)
  case (.value(let x), .value(let f)): return . value(f(x))
  }
}

infix operator <^>: Functional
func <^> <T, U> (f: (T) -> U, x: YAMLResult<T>) -> YAMLResult<U> {
  return x.map(f: f)
}

infix operator >>-: Functional
func >>- <T, U> (x: YAMLResult<T>, f: (T) -> U) -> YAMLResult<U> {
  return x.map(f: f)
}

infix operator >>=-: Functional
func >>=- <T, U> (x: YAMLResult<T>, f: (T) -> YAMLResult<U>) -> YAMLResult<U> {
  return x.flatMap(f: f)
}

infix operator >>|: Functional
func >>| <T, U> (x: YAMLResult<T>, y: YAMLResult<U>) -> YAMLResult<U> {
  return x.flatMap { _ in y }
}

extension Yaml  {
  static func lift <V> (_ v: V) -> YAMLResult<V> {
    return .value(v)
  }

  static func fail <T> (_ e: String) -> YAMLResult<T> {
    return .error(e)
  }

  static func join <T> (_ x: YAMLResult<YAMLResult<T>>) -> YAMLResult<T> {
    return x >>=- { i in i }
  }

  static func `guard` (_ error: @autoclosure() -> String, check: Bool) -> YAMLResult<()> {
    return check ? lift(()) : .error(error())
  }
}

private let invalidOptionsPattern =
  try! NSRegularExpression(pattern: "[^ixsm]", options: [])

private let regexOptions: [Character: NSRegularExpression.Options] = [
  "i": .caseInsensitive,
  "x": .allowCommentsAndWhitespace,
  "s": .dotMatchesLineSeparators,
  "m": .anchorsMatchLines
]

extension Yaml {
  struct Regex {
    static func matchRange (_ string: String, regex: NSRegularExpression) -> NSRange {
      let sr = NSMakeRange(0, string.utf16.count)
      return regex.rangeOfFirstMatch(in: string, options: [], range: sr)
    }

    static func matches (_ string: String, regex: NSRegularExpression) -> Bool {
      return matchRange(string, regex: regex).location != NSNotFound
    }

    static func regex (_ pattern: String, options: String = "") -> NSRegularExpression! {
      if matches(options, regex: invalidOptionsPattern) {
        return nil
      }

      let opts = options.characters.reduce(NSRegularExpression.Options()) {
        (acc, opt) -> NSRegularExpression.Options in
        return NSRegularExpression.Options(rawValue:acc.rawValue | (regexOptions[opt]
          ?? NSRegularExpression.Options()).rawValue)
      }
      return try? NSRegularExpression(pattern: pattern, options: opts)
    }

    static func replace (_ regex: NSRegularExpression, template: String) -> (String)
      -> String {
        return { string in
          let s = NSMutableString(string: string)
          let range = NSMakeRange(0, string.utf16.count)
          _ = regex.replaceMatches(in: s, options: [], range: range,
                                   withTemplate: template)
          #if os(Linux)
            return s._bridgeToSwift()
          #else
            return s as String
          #endif
        }
    }

    static func replace (_ regex: NSRegularExpression, block: @escaping ([String]) -> String)
      -> (String) -> String {
        return { string in
          let s = NSMutableString(string: string)
          let range = NSMakeRange(0, string.utf16.count)
          var offset = 0
          regex.enumerateMatches(in: string, options: [], range: range) {
            result, _, _ in
            if let result = result {
              var captures = [String](repeating: "", count: result.numberOfRanges)
              for i in 0..<result.numberOfRanges {
                #if os(Linux)
                  let rangeAt = result.range(at: i)
                #else
                  let rangeAt = result.range(at: i)
                #endif
                if let r = rangeAt.toRange() {
                  captures[i] = NSString(string: string).substring(with: NSRange(r))
                }
              }
              let replacement = block(captures)
              let offR = NSMakeRange(result.range.location + offset, result.range.length)
              offset += replacement.count - result.range.length
              s.replaceCharacters(in: offR, with: replacement)
            }
          }
          #if os(Linux)
            return s._bridgeToSwift()
          #else
            return s as String
          #endif
        }
    }

    static func splitLead (_ regex: NSRegularExpression) -> (String)
      -> (String, String) {
        return { string in
          let r = matchRange(string, regex: regex)
          if r.location == NSNotFound {
            return ("", string)
          } else {
            let s = NSString(string: string)
            let i = r.location + r.length
            return (s.substring(to: i), s.substring(from: i))
          }
        }
    }

    static func splitTrail (_ regex: NSRegularExpression) -> (String)
      -> (String, String) {
        return { string in
          let r = matchRange(string, regex: regex)
          if r.location == NSNotFound {
            return (string, "")
          } else {
            let s = NSString(string: string)
            let i = r.location
            return (s.substring(to: i), s.substring(from: i))
          }
        }
    }

    static func substringWithRange (_ range: NSRange) -> (String) -> String {
      return { string in
        return NSString(string: string).substring(with: range)
      }
    }

    static func substringFromIndex (_ index: Int) -> (String) -> String {
      return { string in
        return NSString(string: string).substring(from: index)
      }
    }
  }
}

private typealias Resulter = Yaml

extension Yaml {

  struct Context {
    let tokens: [Yaml.TokenMatch]
    let aliases: [String: Yaml]

    init (_ tokens: [Yaml.TokenMatch], _ aliases: [String: Yaml] = [:]) {
      self.tokens = tokens
      self.aliases = aliases
    }
    static func parseDoc (_ tokens: [Yaml.TokenMatch]) -> YAMLResult<Yaml> {
      let c = Resulter.lift(Context(tokens))
      let cv = c >>=- parseHeader >>=- parse
      let v = cv >>- getValue
      return cv
        >>- getContext
        >>- ignoreDocEnd
        >>=- expect(Yaml.TokenType.end, message: "expected end")
        >>| v
    }

    static func parseDocs (_ tokens: [Yaml.TokenMatch]) -> YAMLResult<[Yaml]> {
      return parseDocs([])(Context(tokens))
    }

    static func parseDocs (_ acc: [Yaml]) -> (Context) -> YAMLResult<[Yaml]> {
      return { context in
        if peekType(context) == .end {
          return Resulter.lift(acc)
        }
        let cv = Resulter.lift(context)
          >>=- parseHeader
          >>=- parse
        let v = cv
          >>- getValue
        let c = cv
          >>- getContext
          >>- ignoreDocEnd
        let a = appendToArray(acc) <^> v
        return parseDocs <^> a <*> c |> Resulter.join
      }
    }

    static func error (_ message: String) -> (Context) -> String {
      return { context in
        let text = recreateText("", context: context) |> Yaml.escapeErrorContext
        return "\(message), \(text)"
      }
    }
  }
}

private typealias Context = Yaml.Context

private var error = Yaml.Context.error

private typealias ContextValue = (context: Context, value: Yaml)

private func createContextValue (_ context: Context) -> (Yaml) -> ContextValue {
  return { value in (context, value) }
}

private func getContext (_ cv: ContextValue) -> Context {
  return cv.context
}

private func getValue (_ cv: ContextValue) -> Yaml {
  return cv.value
}


private func peekType (_ context: Context) -> Yaml.TokenType {
  return context.tokens[0].type
}


private func peekMatch (_ context: Context) -> String {
  return context.tokens[0].match
}

private func advance (_ context: Context) -> Context {
  var tokens = context.tokens
  tokens.remove(at: 0)
  return Context(tokens, context.aliases)
}

private func ignoreSpace (_ context: Context) -> Context {
  if ![.comment, .space, .newLine].contains(peekType(context)) {
    return context
  }
  return ignoreSpace(advance(context))
}

private func ignoreDocEnd (_ context: Context) -> Context {
  if ![.comment, .space, .newLine, .docend].contains(peekType(context)) {
    return context
  }
  return ignoreDocEnd(advance(context))
}

private func expect (_ type: Yaml.TokenType, message: String) -> (Context) -> YAMLResult<Context> {
  return { context in
    let check = peekType(context) == type
    return Resulter.`guard`(error(message)(context), check: check)
      >>| Resulter.lift(advance(context))
  }
}

private func expectVersion (_ context: Context) -> YAMLResult<Context> {
  let version = peekMatch(context)
  let check = ["1.1", "1.2"].contains(version)
  return Resulter.`guard`(error("invalid yaml version")(context), check: check)
    >>| Resulter.lift(advance(context))
}


private func recreateText (_ string: String, context: Context) -> String {
  if string.characters.count >= 50 || peekType(context) == .end {
    return string
  }
  return recreateText(string + peekMatch(context), context: advance(context))
}

private func parseHeader (_ context: Context) -> YAMLResult<Context> {
  return parseHeader(true)(Context(context.tokens, [:]))
}

private func parseHeader (_ yamlAllowed: Bool) -> (Context) -> YAMLResult<Context> {
  return { context in
    switch peekType(context) {

    case .comment, .space, .newLine:
      return Resulter.lift(context)
        >>- advance
        >>=- parseHeader(yamlAllowed)

    case .yamlDirective:
      let err = "duplicate yaml directive"
      return Resulter.`guard`(error(err)(context), check: yamlAllowed)
        >>| Resulter.lift(context)
        >>- advance
        >>=- expect(Yaml.TokenType.space, message: "expected space")
        >>=- expectVersion
        >>=- parseHeader(false)

    case .docStart:
      return Resulter.lift(advance(context))

    default:
      return Resulter.`guard`(error("expected ---")(context), check: yamlAllowed)
        >>| Resulter.lift(context)
    }
  }
}

private func parse (_ context: Context) -> YAMLResult<ContextValue> {
  switch peekType(context) {

  case .comment, .space, .newLine:
    return parse(ignoreSpace(context))

  case .null:
    return Resulter.lift((advance(context), nil))

  case ._true:
    return Resulter.lift((advance(context), true))

  case ._false:
    return Resulter.lift((advance(context), false))

  case .int:
    let m = peekMatch(context)
    // will throw runtime error if overflows
    let v = Yaml.int(parseInt(m, radix: 10))
    return Resulter.lift((advance(context), v))

  case .intOct:
    let m = peekMatch(context) |> Yaml.Regex.replace(Yaml.Regex.regex("0o"), template: "")
    // will throw runtime error if overflows
    let v = Yaml.int(parseInt(m, radix: 8))
    return Resulter.lift((advance(context), v))

  case .intHex:
    let m = peekMatch(context) |> Yaml.Regex.replace(Yaml.Regex.regex("0x"), template: "")
    // will throw runtime error if overflows
    let v = Yaml.int(parseInt(m, radix: 16))
    return Resulter.lift((advance(context), v))

  case .intSex:
    let m = peekMatch(context)
    let v = Yaml.int(parseInt(m, radix: 60))
    return Resulter.lift((advance(context), v))

  case .infinityP:
    return Resulter.lift((advance(context), .double(Double.infinity)))

  case .infinityN:
    return Resulter.lift((advance(context), .double(-Double.infinity)))

  case .nan:
    return Resulter.lift((advance(context), .double(Double.nan)))

  case .double:
    let m = NSString(string: peekMatch(context))
    return Resulter.lift((advance(context), .double(m.doubleValue)))

  case .dash:
    return parseBlockSeq(context)

  case .openSB:
    return parseFlowSeq(context)

  case .openCB:
    return parseFlowMap(context)

  case .questionMark:
    return parseBlockMap(context)

  case .stringDQ, .stringSQ, .string:
    return parseBlockMapOrString(context)

  case .literal:
    return parseliteral(context)

  case .folded:
    let cv = parseliteral(context)
    let c = cv >>- getContext
    let v = cv
      >>- getValue
      >>- { value in Yaml.string(foldBlock(value.string ?? "")) }
    return createContextValue <^> c <*> v

  case .indent:
    let cv = parse(advance(context))
    let v = cv >>- getValue
    let c = cv
      >>- getContext
      >>- ignoreSpace
      >>=- expect(Yaml.TokenType.dedent, message: "expected dedent")
    return createContextValue <^> c <*> v

  case .anchor:
    let m = peekMatch(context)
    let name = m.substring(from: m.index(after: m.startIndex))
    let cv = parse(advance(context))
    let v = cv >>- getValue
    let c = addAlias(name) <^> v <*> (cv >>- getContext)
    return createContextValue <^> c <*> v

  case .alias:
    let m = peekMatch(context)
    let name = m.substring(from: m.index(after: m.startIndex))
    let value = context.aliases[name]
    let err = "unknown alias \(name)"
    return Resulter.`guard`(error(err)(context), check: value != nil)
      >>| Resulter.lift((advance(context), value ?? nil))

  case .end, .dedent:
    return Resulter.lift((context, nil))

  default:
    return Resulter.fail(error("unexpected type \(peekType(context))")(context))

  }
}

private func addAlias (_ name: String) -> (Yaml) -> (Context) -> Context {
  return { value in
    return { context in
      var aliases = context.aliases
      aliases[name] = value
      return Context(context.tokens, aliases)
    }
  }
}

private func appendToArray (_ array: [Yaml]) -> (Yaml) -> [Yaml] {
  return { value in
    return array + [value]
  }
}

private func putToMap (_ map: [Yaml: Yaml]) -> (Yaml) -> (Yaml) -> [Yaml: Yaml] {
  return { key in
    return { value in
      var map = map
      map[key] = value
      return map
    }
  }
}

private func checkKeyUniqueness (_ acc: [Yaml: Yaml]) -> (_ context: Context, _ key: Yaml)
  -> YAMLResult<ContextValue> {
    return { (context, key) in
      let err = "duplicate key \(key)"
      return Resulter.`guard`(error(err)(context), check: !acc.keys.contains(key))
        >>| Resulter.lift((context, key))
    }
}

private func parseFlowSeq (_ context: Context) -> YAMLResult<ContextValue> {
  return Resulter.lift(context)
    >>=- expect(Yaml.TokenType.openSB, message: "expected [")
    >>=- parseFlowSeq([])
}

private func parseFlowSeq (_ acc: [Yaml]) -> (Context) -> YAMLResult<ContextValue> {
  return { context in
    if peekType(context) == .closeSB {
      return Resulter.lift((advance(context), .array(acc)))
    }
    let cv = Resulter.lift(context)
      >>- ignoreSpace
      >>=- (acc.count == 0 ? Resulter.lift : expect(Yaml.TokenType.comma, message: "expected comma"))
      >>- ignoreSpace
      >>=- parse
    let v = cv >>- getValue
    let c = cv
      >>- getContext
      >>- ignoreSpace
    let a = appendToArray(acc) <^> v
    return parseFlowSeq <^> a <*> c |> Resulter.join
  }
}

private func parseFlowMap (_ context: Context) -> YAMLResult<ContextValue> {
  return Resulter.lift(context)
    >>=- expect(Yaml.TokenType.openCB, message: "expected {")
    >>=- parseFlowMap([:])
}

private func parseFlowMap (_ acc: [Yaml: Yaml]) -> (Context) -> YAMLResult<ContextValue> {
  return { context in
    if peekType(context) == .closeCB {
      return Resulter.lift((advance(context), .dictionary(acc)))
    }
    let ck = Resulter.lift(context)
      >>- ignoreSpace
      >>=- (acc.count == 0 ? Resulter.lift : expect(Yaml.TokenType.comma,
                                                    message: "expected comma"))
      >>- ignoreSpace
      >>=- parseString
      >>=- checkKeyUniqueness(acc)
    let k = ck >>- getValue
    let cv = ck
      >>- getContext
      >>=- expect(Yaml.TokenType.colon, message: "expected colon")
      >>=- parse
    let v = cv >>- getValue
    let c = cv
      >>- getContext
      >>- ignoreSpace
    let a = putToMap(acc) <^> k <*> v
    return parseFlowMap <^> a <*> c |> Resulter.join
  }
}

private func parseBlockSeq (_ context: Context) -> YAMLResult<ContextValue> {
  return parseBlockSeq([])(context)
}

private func parseBlockSeq (_ acc: [Yaml]) -> (Context) -> YAMLResult<ContextValue> {
  return { context in
    if peekType(context) != .dash {
      return Resulter.lift((context, .array(acc)))
    }
    let cv = Resulter.lift(context)
      >>- advance
      >>=- expect(Yaml.TokenType.indent, message: "expected indent after dash")
      >>- ignoreSpace
      >>=- parse
    let v = cv >>- getValue
    let c = cv
      >>- getContext
      >>- ignoreSpace
      >>=- expect(Yaml.TokenType.dedent, message: "expected dedent after dash indent")
      >>- ignoreSpace
    let a = appendToArray(acc) <^> v
    return parseBlockSeq <^> a <*> c |> Resulter.join
  }
}

private func parseBlockMap (_ context: Context) -> YAMLResult<ContextValue> {
  return parseBlockMap([:])(context)
}

private func parseBlockMap (_ acc: [Yaml: Yaml]) -> (Context) -> YAMLResult<ContextValue> {
  return { context in
    switch peekType(context) {

    case .questionMark:
      return parseQuestionMarkkeyValue(acc)(context)

    case .string, .stringDQ, .stringSQ:
      return parseStringKeyValue(acc)(context)

    default:
      return Resulter.lift((context, .dictionary(acc)))
    }
  }
}

private func parseQuestionMarkkeyValue (_ acc: [Yaml: Yaml]) -> (Context)
  -> YAMLResult<ContextValue> {
    return { context in
      let ck = Resulter.lift(context)
        >>=- expect(Yaml.TokenType.questionMark, message: "expected ?")
        >>=- parse
        >>=- checkKeyUniqueness(acc)
      let k = ck >>- getValue
      let cv = ck
        >>- getContext
        >>- ignoreSpace
        >>=- parseColonValueOrNil
      let v = cv >>- getValue
      let c = cv
        >>- getContext
        >>- ignoreSpace
      let a = putToMap(acc) <^> k <*> v
      return parseBlockMap <^> a <*> c |> Resulter.join
    }
}

private func parseColonValueOrNil (_ context: Context) -> YAMLResult<ContextValue> {
  if peekType(context) != .colon {
    return Resulter.lift((context, nil))
  }
  return parseColonValue(context)
}

private func parseColonValue (_ context: Context) -> YAMLResult<ContextValue> {
  return Resulter.lift(context)
    >>=- expect(Yaml.TokenType.colon, message: "expected colon")
    >>- ignoreSpace
    >>=- parse
}

private func parseStringKeyValue (_ acc: [Yaml: Yaml]) -> (Context) -> YAMLResult<ContextValue> {
  return { context in
    let ck = Resulter.lift(context)
      >>=- parseString
      >>=- checkKeyUniqueness(acc)
    let k = ck >>- getValue
    let cv = ck
      >>- getContext
      >>- ignoreSpace
      >>=- parseColonValue
    let v = cv >>- getValue
    let c = cv
      >>- getContext
      >>- ignoreSpace
    let a = putToMap(acc) <^> k <*> v
    return parseBlockMap <^> a <*> c |> Resulter.join
  }
}

private func parseString (_ context: Context) -> YAMLResult<ContextValue> {
  switch peekType(context) {

  case .string:
    let m = normalizeBreaks(peekMatch(context))
    let folded = m |> Yaml.Regex.replace(Yaml.Regex.regex("^[ \\t\\n]+|[ \\t\\n]+$"), template: "")
      |> foldFlow
    return Resulter.lift((advance(context), .string(folded)))

  case .stringDQ:
    let m = unwrapQuotedString(normalizeBreaks(peekMatch(context)))
    return Resulter.lift((advance(context), .string(unescapeDoubleQuotes(foldFlow(m)))))

  case .stringSQ:
    let m = unwrapQuotedString(normalizeBreaks(peekMatch(context)))
    return Resulter.lift((advance(context), .string(unescapeSingleQuotes(foldFlow(m)))))

  default:
    return Resulter.fail(error("expected string")(context))
  }
}


private func parseBlockMapOrString (_ context: Context) -> YAMLResult<ContextValue> {
  let match = peekMatch(context)
  // should spaces before colon be ignored?
  return context.tokens[1].type != .colon || Yaml.Regex.matches(match,
                                                                regex: Yaml.Regex.regex("\n"))
    ? parseString(context)
    : parseBlockMap(context)
}

private func foldBlock (_ block: String) -> String {
  let (body, trail) = block |> Yaml.Regex.splitTrail(Yaml.Regex.regex("\\n*$"))
  return (body
    |> Yaml.Regex.replace(Yaml.Regex.regex("^([^ \\t\\n].*)\\n(?=[^ \\t\\n])", options: "m"),
                          template: "$1 ")
    |> Yaml.Regex.replace(
      Yaml.Regex.regex("^([^ \\t\\n].*)\\n(\\n+)(?![ \\t])", options: "m"), template: "$1$2")
    ) + trail
}

private func foldFlow (_ flow: String) -> String {
  let (lead, rest) = flow |> Yaml.Regex.splitLead(Yaml.Regex.regex("^[ \\t]+"))
  let (body, trail) = rest |> Yaml.Regex.splitTrail(Yaml.Regex.regex("[ \\t]+$"))
  let folded = body
    |> Yaml.Regex.replace(Yaml.Regex.regex("^[ \\t]+|[ \\t]+$|\\\\\\n", options: "m"), template: "")
    |> Yaml.Regex.replace(Yaml.Regex.regex("(^|.)\\n(?=.|$)"), template: "$1 ")
    |> Yaml.Regex.replace(Yaml.Regex.regex("(.)\\n(\\n+)"), template: "$1$2")
  return lead + folded + trail
}

private func count(string: String) -> String.IndexDistance {
  return string.characters.count
}

private func parseliteral (_ context: Context) -> YAMLResult<ContextValue> {
  let literal = peekMatch(context)
  let blockContext = advance(context)
  let chomps = ["-": -1, "+": 1]
  let chomp = chomps[literal |> Yaml.Regex.replace(Yaml.Regex.regex("[^-+]"), template: "")] ?? 0
  let indent = parseInt(literal |> Yaml.Regex.replace(Yaml.Regex.regex("[^1-9]"), template: ""),
                        radix: 10)
  let headerPattern = Yaml.Regex.regex("^(\\||>)([1-9][-+]|[-+]?[1-9]?)( |$)")
  let error0 = "invalid chomp or indent header"
  let c = Resulter.`guard`(error(error0)(context),
                           check: Yaml.Regex.matches(literal, regex: headerPattern!))
    >>| Resulter.lift(blockContext)
    >>=- expect(Yaml.TokenType.string, message: "expected scalar block")
  let block = peekMatch(blockContext)
    |> normalizeBreaks
  let (lead, _) = block
    |> Yaml.Regex.splitLead(Yaml.Regex.regex("^( *\\n)* {1,}(?! |\\n|$)"))
  let foundindent = lead
    |> Yaml.Regex.replace(Yaml.Regex.regex("^( *\\n)*"), template: "")
    |> count
  let effectiveindent = indent > 0 ? indent : foundindent
  let invalidPattern =
    Yaml.Regex.regex("^( {0,\(effectiveindent)}\\n)* {\(effectiveindent + 1),}\\n")
  let check1 = Yaml.Regex.matches(block, regex: invalidPattern!)
  let check2 = indent > 0 && foundindent < indent
  let trimmed = block
    |> Yaml.Regex.replace(Yaml.Regex.regex("^ {0,\(effectiveindent)}"), template: "")
    |> Yaml.Regex.replace(Yaml.Regex.regex("\\n {0,\(effectiveindent)}"), template: "\n")
    |> (chomp == -1
      ? Yaml.Regex.replace(Yaml.Regex.regex("(\\n *)*$"), template: "")
      : chomp == 0
      ? Yaml.Regex.replace(Yaml.Regex.regex("(?=[^ ])(\\n *)*$"), template: "\n")
      : { s in s }
  )
  let error1 = "leading all-space line must not have too many spaces"
  let error2 = "less indented block scalar than the indicated level"
  return c
    >>| Resulter.`guard`(error(error1)(blockContext), check: !check1)
    >>| Resulter.`guard`(error(error2)(blockContext), check: !check2)
    >>| c
    >>- { context in (context, .string(trimmed))}
}


private func parseInt (_ string: String, radix: Int) -> Int {
  let (sign, str) = Yaml.Regex.splitLead(Yaml.Regex.regex("^[-+]"))(string)
  let multiplier = (sign == "-" ? -1 : 1)
  let ints = radix == 60
    ? toSexints(str)
    : toints(str)
  return multiplier * ints.reduce(0, { acc, i in acc * radix + i })
}

private func toSexints (_ string: String) -> [Int] {
  return string.components(separatedBy: ":").map {
    c in Int(c) ?? 0
  }
}

private func toints (_ string: String) -> [Int] {
  return string.unicodeScalars.map {
    c in
    switch c {
    case "0"..."9": return Int(c.value) - Int(("0" as UnicodeScalar).value)
    case "a"..."z": return Int(c.value) - Int(("a" as UnicodeScalar).value) + 10
    case "A"..."Z": return Int(c.value) - Int(("A" as UnicodeScalar).value) + 10
    default: fatalError("invalid digit \(c)")
    }
  }
}

private func normalizeBreaks (_ s: String) -> String {
  return Yaml.Regex.replace(Yaml.Regex.regex("\\r\\n|\\r"), template: "\n")(s)
}

private func unwrapQuotedString (_ s: String) -> String {
  return String(s[s.index(after: s.startIndex)..<s.index(before: s.endIndex)])
}

private func unescapeSingleQuotes (_ s: String) -> String {
  return Yaml.Regex.replace(Yaml.Regex.regex("''"), template: "'")(s)
}

private func unescapeDoubleQuotes (_ input: String) -> String {
  return input
    |> Yaml.Regex.replace(Yaml.Regex.regex("\\\\([0abtnvfre \"\\/N_LP])"))
    { escapeCharacters[$0[1]] ?? "" }
    |> Yaml.Regex.replace(Yaml.Regex.regex("\\\\x([0-9A-Fa-f]{2})"))
    { String(describing: UnicodeScalar(parseInt($0[1], radix: 16))) }
    |> Yaml.Regex.replace(Yaml.Regex.regex("\\\\u([0-9A-Fa-f]{4})"))
    { String(describing: UnicodeScalar(parseInt($0[1], radix: 16))) }
    |> Yaml.Regex.replace(Yaml.Regex.regex("\\\\U([0-9A-Fa-f]{8})"))
    { String(describing: UnicodeScalar(parseInt($0[1], radix: 16))) }
}

private let escapeCharacters = [
  "0": "\0",
  "a": "\u{7}",
  "b": "\u{8}",
  "t": "\t",
  "n": "\n",
  "v": "\u{B}",
  "f": "\u{C}",
  "r": "\r",
  "e": "\u{1B}",
  " ": " ",
  "\"": "\"",
  "\\": "\\",
  "/": "/",
  "N": "\u{85}",
  "_": "\u{A0}",
  "L": "\u{2028}",
  "P": "\u{2029}"
]
