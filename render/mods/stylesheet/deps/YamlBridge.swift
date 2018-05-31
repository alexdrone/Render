//#if RENDER_MOD_STYLESHEET
import Foundation

final class YAMLConstructor {
  typealias Map = [YAMLTag.Name: (YAMLNode) -> Any?]
  init(_ map: Map) {
    methodMap = map
  }
  func any(from node: YAMLNode) -> Any {
    if let method = methodMap[node.tag.name], let result = method(node) {
      return result
    }
    switch node {
    case .scalar:
      return String._construct(from: node)
    case .mapping:
      return [AnyHashable: Any]._construct_mapping(from: node)
    case .sequence:
      return [Any].construct_seq(from: node)
    }
  }
  private let methodMap: Map
}

extension YAMLConstructor {
  static let `default` = YAMLConstructor(defaultMap)
  // We can not write extension of map because that is alias of specialized dictionary
  static let defaultMap: Map = [
    // Failsafe Schema
    .map: [AnyHashable: Any].construct_mapping,
    .str: String.construct,
    .seq: [Any].construct_seq,
    // JSON Schema
    .bool: Bool.construct,
    .float: Double.construct,
    .null: NSNull.construct,
    .int: Int.construct,
    // http://yaml.org/type/index.html
    .binary: Data.construct,
    // .merge is supported in `[AnyHashable: Any].construct`.
    .omap: [Any].construct_omap,
    .pairs: [Any].construct_pairs,
    .set: Set<AnyHashable>.construct_set,
    .timestamp: Date.construct
    // .value is supported in `String.construct` and `[AnyHashable: Any].construct`.
  ]
}

// MARK: - ScalarConstructible
protocol YAMLScalarConstructible {
  // We don't use overloading `init?(_ node: YAMLNode)`
  // because that causes difficulties on using `init` as closure
  static func construct(from node: YAMLNode) -> Self?
}

extension Bool: YAMLScalarConstructible {
  static func construct(from node: YAMLNode) -> Bool? {
    assert(node.isScalar) // swiftlint:disable:next force_unwrapping
    switch node.scalar!.string.lowercased() {
    case "true", "yes", "on":
      return true
    case "false", "no", "off":
      return false
    default:
      return nil
    }
  }
}

extension Data: YAMLScalarConstructible {
  static func construct(from node: YAMLNode) -> Data? {
    assert(node.isScalar) // swiftlint:disable:next force_unwrapping
    let data = Data(base64Encoded: node.scalar!.string, options: .ignoreUnknownCharacters)
    return data
  }
}

extension Date: YAMLScalarConstructible {
  static func construct(from node: YAMLNode) -> Date? {
    assert(node.isScalar) // swiftlint:disable:next force_unwrapping
    let scalar = node.scalar!.string
    let range = NSRange(location: 0, length: scalar.utf16.count)
    guard let result = timestampPattern.firstMatch(in: scalar, options: [], range: range),
      result.range.location != NSNotFound else {
        return nil
    }
    #if os(Linux) || swift(>=4.0)
      let components = (1..<result.numberOfRanges).map {
        scalar.substring(with: result.range(at: $0))
      }
    #else
      let components = (1..<result.numberOfRanges).map {
        scalar.substring(with: result.rangeAt($0))
      }
    #endif
    var datecomponents = DateComponents()
    datecomponents.calendar = Calendar(identifier: .gregorian)
    datecomponents.year = components[0].flatMap { Int($0) }
    datecomponents.month = components[1].flatMap { Int($0) }
    datecomponents.day = components[2].flatMap { Int($0) }
    datecomponents.hour = components[3].flatMap { Int($0) }
    datecomponents.minute = components[4].flatMap { Int($0) }
    datecomponents.second = components[5].flatMap { Int($0) }
    datecomponents.nanosecond = components[6].flatMap {
      let length = $0.count
      let nanosecond: Int?
      if length < 9 {
        nanosecond = Int($0 + String(repeating: "0", count: 9 - length))
      } else {
        nanosecond = Int($0[..<$0.index($0.startIndex, offsetBy: 9)])
      }
      return nanosecond
    }
    datecomponents.timeZone = {
      var seconds = 0
      if let hourInSecond = components[9].flatMap({ Int($0) }).map({ $0 * 60 * 60 }) {
        seconds += hourInSecond
      }
      if let minuteInSecond = components[10].flatMap({ Int($0) }).map({ $0 * 60 }) {
        seconds += minuteInSecond
      }
      if components[8] == "-" { // sign
        seconds *= -1
      }
      return TimeZone(secondsFromGMT: seconds)
    }()
    // Using `DateComponents.date` causes `NSUnimplemented()` crash on Linux at swift-3.0.2-RELEASE
    return NSCalendar(identifier: .gregorian)?.date(from: datecomponents)
  }

  private static let timestampPattern: NSRegularExpression = pattern([
    "^([0-9][0-9][0-9][0-9])",          // year
    "-([0-9][0-9]?)",                   // month
    "-([0-9][0-9]?)",                   // day
    "(?:(?:[Tt]|[ \\t]+)",
    "([0-9][0-9]?)",                    // hour
    ":([0-9][0-9])",                    // minute
    ":([0-9][0-9])",                    // second
    "(?:\\.([0-9]*))?",                 // fraction
    "(?:[ \\t]*(Z|([-+])([0-9][0-9]?)", // tz_sign, tz_hour
    "(?::([0-9][0-9]))?))?)?$"          // tz_minute
    ].joined()
  )
}

extension Double: YAMLScalarConstructible {}
extension Float: YAMLScalarConstructible {}
extension YAMLScalarConstructible where Self: FloatingPoint & SexagesimalConvertible {
  static func construct(from node: YAMLNode) -> Self? {
    assert(node.isScalar) // swiftlint:disable:next force_unwrapping
    var scalar = node.scalar!.string
    switch scalar {
    case ".inf", ".Inf", ".INF", "+.inf", "+.Inf", "+.INF":
      return .infinity
    case "-.inf", "-.Inf", "-.INF":
      return -Self.infinity
    case ".nan", ".NaN", ".NAN":
      return .nan
    default:
      scalar = scalar.replacingOccurrences(of: "_", with: "")
      if scalar.contains(":") {
        return Self(sexagesimal: scalar)
      }
      return .create(from: scalar)
    }
  }
}

extension FixedWidthInteger where Self: SexagesimalConvertible {
  fileprivate static func _construct(from node: YAMLNode) -> Self? {
    assert(node.isScalar) // swiftlint:disable:next force_unwrapping
    let scalarWithSign = node.scalar!.string.replacingOccurrences(of: "_", with: "")
    if scalarWithSign == "0" {
      return 0
    }
    let negative = scalarWithSign.hasPrefix("-")
    guard isSigned || !negative else { return nil }
    let signPrefix = negative ? "-" : ""
    let hasSign = negative || scalarWithSign.hasPrefix("+")
    let prefixToRadix: [(String, Int)] = [
      ("0x", 16),
      ("0b", 2),
      ("0o", 8),
      ("0", 8)
    ]
    let scalar = scalarWithSign.substring(from: hasSign ? 1 : 0)
    for (prefix, radix) in prefixToRadix where scalar.hasPrefix(prefix) {
      return Self(signPrefix + scalar.substring(from: prefix.count), radix: radix)
    }
    if scalar.contains(":") {
      return Self(sexagesimal: scalarWithSign)
    }
    return Self(scalarWithSign)
  }
}

extension Int: YAMLScalarConstructible {
  static func construct(from node: YAMLNode) -> Int? {
    return _construct(from: node)
  }
}

extension UInt: YAMLScalarConstructible {
  static func construct(from node: YAMLNode) -> UInt? {
    return _construct(from: node)
  }
}

extension String: YAMLScalarConstructible {
  static func construct(from node: YAMLNode) -> String? {
    return _construct(from: node)
  }

  fileprivate static func _construct(from node: YAMLNode) -> String {
    // This will happen while `Dictionary.flatten_mapping()` if `node.tag.name` was `.value`
    if case let .mapping(mapping) = node {
      for (key, value) in mapping where key.tag.name == .value {
        return _construct(from: value)
      }
    }
    assert(node.isScalar) // swiftlint:disable:next force_unwrapping
    return node.scalar!.string
  }
}

// MARK: - Types that can't conform to ScalarConstructible

extension NSNull/*: ScalarConstructible*/ {
  static func construct(from node: YAMLNode) -> NSNull? {
    guard let string = node.scalar?.string else { return nil }
    switch string {
    case "", "~", "null", "Null", "NULL":
      return NSNull()
    default:
      return nil
    }
  }
}

// MARK: mapping

extension Dictionary {
  static func construct_mapping(from node: YAMLNode) -> [AnyHashable: Any]? {
    return _construct_mapping(from: node)
  }

  fileprivate static func _construct_mapping(from node: YAMLNode) -> [AnyHashable: Any] {
    assert(node.isMapping) // swiftlint:disable:next force_unwrapping
    let mapping = flatten_mapping(node).mapping!
    var dictionary = [AnyHashable: Any](minimumCapacity: mapping.count)
    mapping.forEach {
      // TODO: YAML supports keys other than str.
      dictionary[String._construct(from: $0.key)] = node.tag.constructor.any(from: $0.value)
    }
    return dictionary
  }

  private static func flatten_mapping(_ node: YAMLNode) -> YAMLNode {
    assert(node.isMapping) // swiftlint:disable:next force_unwrapping
    let mapping = node.mapping!
    var pairs = Array(mapping)
    var merge = [(key: YAMLNode, value: YAMLNode)]()
    var index = pairs.startIndex
    while index < pairs.count {
      let pair = pairs[index]
      if pair.key.tag.name == .merge {
        pairs.remove(at: index)
        switch pair.value {
        case .mapping:
          let flattened_node = flatten_mapping(pair.value)
          if let mapping = flattened_node.mapping {
            merge.append(contentsOf: mapping)
          }
        case let .sequence(sequence):
          let submerge = sequence
            .filter { $0.isMapping } // TODO: Should raise error on other than mapping
            .compactMap { flatten_mapping($0).mapping }
            .reversed()
          submerge.forEach {
            merge.append(contentsOf: $0)
          }
        default:
          break // TODO: Should raise error on other than mapping or sequence
        }
      } else if pair.key.tag.name == .value {
        pair.key.tag.name = .str
        index += 1
      } else {
        index += 1
      }
    }
    return YAMLNode(merge + pairs, node.tag, mapping.style)
  }
}

extension Set {
  static func construct_set(from node: YAMLNode) -> Set<AnyHashable>? {
    // TODO: YAML supports Hashable elements other than str.
    assert(node.isMapping) // swiftlint:disable:next force_unwrapping
    return Set<AnyHashable>(node.mapping!.map({ String._construct(from: $0.key) as AnyHashable }))
    // Explicitly declaring the generic parameter as `<AnyHashable>` above is required,
    // because this is inside extension of `Set` and Swift 3.0.2 can't infer the type without that.
  }
}

// MARK: sequence
extension Array {
  static func construct_seq(from node: YAMLNode) -> [Any] {
    // swiftlint:disable:next force_unwrapping
    return node.sequence!.map(node.tag.constructor.any)
  }

  static func construct_omap(from node: YAMLNode) -> [(Any, Any)] {
    // Note: we do not check for duplicate keys.
    assert(node.isSequence) // swiftlint:disable:next force_unwrapping
    return node.sequence!.compactMap { subnode -> (Any, Any)? in
      // TODO: Should raise error if subnode is not mapping or mapping.count != 1
      guard let (key, value) = subnode.mapping?.first else { return nil }
      return (node.tag.constructor.any(from: key), node.tag.constructor.any(from: value))
    }
  }

  static func construct_pairs(from node: YAMLNode) -> [(Any, Any)] {
    // Note: we do not check for duplicate keys.
    assert(node.isSequence) // swiftlint:disable:next force_unwrapping
    return node.sequence!.compactMap { subnode -> (Any, Any)? in
      // TODO: Should raise error if subnode is not mapping or mapping.count != 1
      guard let (key, value) = subnode.mapping?.first else { return nil }
      return (node.tag.constructor.any(from: key), node.tag.constructor.any(from: value))
    }
  }
}

fileprivate extension String {
  func substring(with range: NSRange) -> Substring? {
    guard range.location != NSNotFound else { return nil }
    let utf16lowerBound = utf16.index(utf16.startIndex, offsetBy: range.location)
    let utf16upperBound = utf16.index(utf16lowerBound, offsetBy: range.length)
    guard let lowerBound = utf16lowerBound.samePosition(in: self),
      let upperBound = utf16upperBound.samePosition(in: self) else {
        fatalError("unreachable")
    }
    return self[lowerBound..<upperBound]
  }
}

fileprivate extension String {
  func substring(from offset: Int) -> Substring {
    let index = self.index(startIndex, offsetBy: offset)
    return self[index...]
  }
}

// MARK: - SexagesimalConvertible
protocol SexagesimalConvertible: ExpressibleByIntegerLiteral {
  static func create(from string: String) -> Self?
  static func * (lhs: Self, rhs: Self) -> Self
  static func + (lhs: Self, rhs: Self) -> Self
}

extension SexagesimalConvertible {
  fileprivate init(sexagesimal value: String) {
    self = value.sexagesimal()
  }
}

extension SexagesimalConvertible where Self: LosslessStringConvertible {
  static func create(from string: String) -> Self? {
    return Self(string)
  }
}

extension SexagesimalConvertible where Self: FixedWidthInteger {
  static func create(from string: String) -> Self? {
    return Self(string, radix: 10)
  }
}

extension Double: SexagesimalConvertible {}
extension Float: SexagesimalConvertible {}
extension Int: SexagesimalConvertible {}
extension UInt: SexagesimalConvertible {}

fileprivate extension String {
  func sexagesimal<T>() -> T where T: SexagesimalConvertible {
    assert(contains(":"))
    var scalar = self
    let sign: T
    if scalar.hasPrefix("-") {
      sign = -1
      scalar = String(scalar.substring(from: 1))
    } else if scalar.hasPrefix("+") {
      scalar = String(scalar.substring(from: 1))
      sign = 1
    } else {
      sign = 1
    }
    let digits = scalar.components(separatedBy: ":").compactMap(T.create).reversed()
    let (_, value) = digits.reduce((1, 0) as (T, T)) { baseAndValue, digit in
      let value = baseAndValue.1 + (digit * baseAndValue.0)
      let base = baseAndValue.0 * 60
      return (base, value)
    }
    return sign * value
  }
}

fileprivate extension Substring {
  #if os(Linux)
  func hasPrefix(_ prefix: String) -> Bool {
  return String(self).hasPrefix(prefix)
  }
  func components(separatedBy separator: String) -> [String] {
  return String(self).components(separatedBy: separator)
  }
  #endif
  func substring(from offset: Int) -> Substring {
    if offset == 0 { return self }
    let index = self.index(startIndex, offsetBy: offset)
    return self[index...]
  }
}

extension FixedWidthInteger where Self: SignedInteger {
  static func construct(from node: YAMLNode) -> Self? {
    guard let int = Int.construct(from: node) else { return nil }
    return Self.init(exactly: int)
  }
}

extension FixedWidthInteger where Self: UnsignedInteger {
  static func construct(from node: YAMLNode) -> Self? {
    guard let int = UInt.construct(from: node) else { return nil }
    return Self.init(exactly: int)
  }
}

extension Int16: YAMLScalarConstructible {}
extension Int32: YAMLScalarConstructible {}
extension Int64: YAMLScalarConstructible {}
extension Int8: YAMLScalarConstructible {}
extension UInt16: YAMLScalarConstructible {}
extension UInt32: YAMLScalarConstructible {}
extension UInt64: YAMLScalarConstructible {}
extension UInt8: YAMLScalarConstructible {}

extension Decimal: YAMLScalarConstructible {
  static func construct(from node: YAMLNode) -> Decimal? {
    assert(node.isScalar) // swiftlint:disable:next force_unwrapping
    return Decimal(string: node.scalar!.string)
  }
}

extension URL: YAMLScalarConstructible {
  static func construct(from node: YAMLNode) -> URL? {
    assert(node.isScalar) // swiftlint:disable:next force_unwrapping
    return URL(string: node.scalar!.string)
  }
}

struct _YAMLCodingKey: CodingKey {
  var stringValue: String
  var intValue: Int?

  init?(stringValue: String) {
    self.stringValue = stringValue
    self.intValue = nil
  }

  init?(intValue: Int) {
    self.stringValue = "\(intValue)"
    self.intValue = intValue
  }

  init(index: Int) {
    self.stringValue = "Index \(index)"
    self.intValue = index
  }

  static let `super` = _YAMLCodingKey(stringValue: "super")!
}

private extension YAMLNode {
  static let null = YAMLNode("null", YAMLTag(.null))
  static let unused = YAMLNode("", .unused)
}

private extension YAMLTag {
  static let unused = YAMLTag(.unused)
}

private extension YAMLTag.Name {
  static let unused: YAMLTag.Name = "tag:yams.encoder:unused"
}

/// The pointer position
struct YAMLMark {
  /// line start from 1
  let line: Int
  /// column start from 1. libYAML counts columns in `UnicodeScalar`.
  let column: Int
}

extension YAMLMark: CustomStringConvertible {
  /// A textual representation of this instance.
  var description: String { return "\(line):\(column)" }
}

extension YAMLMark {
  /// Returns snippet string pointed by YAMLMark instance from YAML String
  func snippet(from yaml: String) -> String {
    let contents = yaml.substring(at: line - 1)
    let columnIndex = contents.unicodeScalars
      .index(contents.unicodeScalars.startIndex,
             offsetBy: column - 1,
             limitedBy: contents.unicodeScalars.endIndex)?
      .samePosition(in: contents.utf16) ?? contents.utf16.endIndex
    let columnInUTF16 = contents.utf16.distance(from: contents.utf16.startIndex, to: columnIndex)
    return contents.endingWithNewLine +
      String(repeating: " ", count: columnInUTF16) + "^"
  }
}

enum YAMLNode {
  case scalar(Scalar)
  case mapping(Mapping)
  case sequence(Sequence)
}

extension YAMLNode {
  init(_ string: String, _ tag: YAMLTag = .implicit, _ style: Scalar.Style = .any) {
    self = .scalar(.init(string, tag, style))
  }

  init(_ pairs: [(YAMLNode, YAMLNode)],
              _ tag: YAMLTag = .implicit,
              _ style: Mapping.Style = .any) {
    self = .mapping(.init(pairs, tag, style))
  }

  init(_ nodes: [YAMLNode], _ tag: YAMLTag = .implicit, _ style: Sequence.Style = .any) {
    self = .sequence(.init(nodes, tag, style))
  }
}

extension YAMLNode {
  /// Accessing this property causes the tag to be resolved by tag.resolver.
  var tag: YAMLTag {
    switch self {
    case let .scalar(scalar): return scalar.resolvedYAMLTag
    case let .mapping(mapping): return mapping.resolvedYAMLTag
    case let .sequence(sequence): return sequence.resolvedYAMLTag
    }
  }

  var mark: YAMLMark? {
    switch self {
    case let .scalar(scalar): return scalar.mark
    case let .mapping(mapping): return mapping.mark
    case let .sequence(sequence): return sequence.mark
    }
  }

  // MARK: typed accessor properties
  var any: Any {
    return tag.constructor.any(from: self)
  }

  var string: String? {
    return String.construct(from: self)
  }

  var bool: Bool? {
    return Bool.construct(from: self)
  }

  var float: Double? {
    return Double.construct(from: self)
  }

  var null: NSNull? {
    return NSNull.construct(from: self)
  }

  var int: Int? {
    return Int.construct(from: self)
  }

  var binary: Data? {
    return Data.construct(from: self)
  }

  var timestamp: Date? {
    return Date.construct(from: self)
  }

  // MARK: Typed accessor methods

  /// - Returns: Array of `YAMLNode`
  func array() -> [YAMLNode] {
    return sequence.map(Array.init) ?? []
  }

  func array<Type: YAMLScalarConstructible>() -> [Type] {
    return sequence?.compactMap(Type.construct) ?? []
  }

  /// Typed Array using type parameter: e.g. `array(of: String.self)`
  ///
  /// - Parameter type: Type conforms to ScalarConstructible
  /// - Returns: Array of `Type`
  func array<Type: YAMLScalarConstructible>(of type: Type.Type) -> [Type] {
    return sequence?.compactMap(Type.construct) ?? []
  }

  subscript(node: YAMLNode) -> YAMLNode? {
    get {
      switch self {
      case .scalar: return nil
      case let .mapping(mapping):
        return mapping[node]
      case let .sequence(sequence):
        guard let index = node.int, sequence.indices ~= index else { return nil }
        return sequence[index]
      }
    }
    set {
      guard let newValue = newValue else { return }
      switch self {
      case .scalar: return
      case .mapping(var mapping):
        mapping[node] = newValue
        self = .mapping(mapping)
      case .sequence(var sequence):
        guard let index = node.int, sequence.indices ~= index else { return}
        sequence[index] = newValue
        self = .sequence(sequence)
      }
    }
  }

  subscript(representable: YAMLNodeRepresentable) -> YAMLNode? {
    get {
      guard let node = try? representable.represented() else { return nil }
      return self[node]
    }
    set {
      guard let node = try? representable.represented() else { return }
      self[node] = newValue
    }
  }

  subscript(string: String) -> YAMLNode? {
    get {
      return self[YAMLNode(string)]
    }
    set {
      self[YAMLNode(string)] = newValue
    }
  }
}

// MARK: Hashable

extension YAMLNode: Hashable {
  var hashValue: Int {
    switch self {
    case let .scalar(scalar):
      return scalar.string.hashValue
    case let .mapping(mapping):
      return mapping.count
    case let .sequence(sequence):
      return sequence.count
    }
  }

  static func == (lhs: YAMLNode, rhs: YAMLNode) -> Bool {
    switch (lhs, rhs) {
    case let (.scalar(lhs), .scalar(rhs)):
      return lhs == rhs
    case let (.mapping(lhs), .mapping(rhs)):
      return lhs == rhs
    case let (.sequence(lhs), .sequence(rhs)):
      return lhs == rhs
    default:
      return false
    }
  }
}

extension YAMLNode: Comparable {
  static func < (lhs: YAMLNode, rhs: YAMLNode) -> Bool {
    switch (lhs, rhs) {
    case let (.scalar(lhs), .scalar(rhs)):
      return lhs < rhs
    case let (.mapping(lhs), .mapping(rhs)):
      return lhs < rhs
    case let (.sequence(lhs), .sequence(rhs)):
      return lhs < rhs
    default:
      return false
    }
  }
}

extension Array where Element: Comparable {
  static func < (lhs: Array, rhs: Array) -> Bool {
    for (lhs, rhs) in zip(lhs, rhs) {
      if lhs < rhs {
        return true
      } else if lhs > rhs {
        return false
      }
    }
    return lhs.count < rhs.count
  }
}

// MARK: - ExpressibleBy*Literal

extension YAMLNode: ExpressibleByArrayLiteral {
  init(arrayLiteral elements: YAMLNode...) {
    self = .sequence(.init(elements))
  }
}

extension YAMLNode: ExpressibleByDictionaryLiteral {
  init(dictionaryLiteral elements: (YAMLNode, YAMLNode)...) {
    self = YAMLNode(elements)
  }
}

extension YAMLNode: ExpressibleByFloatLiteral {
  init(floatLiteral value: Double) {
    self.init(String(value), YAMLTag(.float))
  }
}

extension YAMLNode: ExpressibleByIntegerLiteral {
  init(integerLiteral value: Int) {
    self.init(String(value), YAMLTag(.int))
  }
}

extension YAMLNode: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    self.init(value)
  }
}

// MARK: - internal

extension YAMLNode {
  // MARK: Internal convenience accessors
  var isScalar: Bool {
    if case .scalar = self {
      return true
    }
    return false
  }

  var isMapping: Bool {
    if case .mapping = self {
      return true
    }
    return false
  }

  var isSequence: Bool {
    if case .sequence = self {
      return true
    }
    return false
  }
}

extension YAMLNode {
  struct Scalar {
    var string: String {
      didSet {
        tag = .implicit
      }
    }
    var tag: YAMLTag
    var style: Style
    var mark: YAMLMark?

    enum Style: UInt32 { // swiftlint:disable:this nesting
      /// Let the emitter choose the style.
      case any = 0
      /// The plain scalar style.
      case plain
      /// The single-quoted scalar style.
      case singleQuoted
      /// The double-quoted scalar style.
      case doubleQuoted
      /// The literal scalar style.
      case literal
      /// The folded scalar style.
      case folded
    }

    init(_ string: String,
                _ tag: YAMLTag = .implicit,
                _ style: Style = .any,
                _ mark: YAMLMark? = nil) {
      self.string = string
      self.tag = tag
      self.style = style
      self.mark = mark
    }
  }

  var scalar: Scalar? {
    get {
      if case let .scalar(scalar) = self {
        return scalar
      }
      return nil
    }
    set {
      if let newValue = newValue {
        self = .scalar(newValue)
      }
    }
  }
}

extension YAMLNode.Scalar: Comparable {
  static func < (lhs: YAMLNode.Scalar, rhs: YAMLNode.Scalar) -> Bool {
    return lhs.string < rhs.string
  }
}

extension YAMLNode.Scalar: Equatable {
  static func == (lhs: YAMLNode.Scalar, rhs: YAMLNode.Scalar) -> Bool {
    return lhs.string == rhs.string && lhs.resolvedYAMLTag == rhs.resolvedYAMLTag
  }
}

extension YAMLNode.Scalar: YAMLTagResolvable {
  static let defaultYAMLTagName = YAMLTag.Name.str
  func resolveYAMLTag(using resolver: YAMLResolver) -> YAMLTag.Name {
    return tag.name == .implicit ? resolver.resolveYAMLTag(from: string) : tag.name
  }
}


extension YAMLNode {
  struct Mapping {
    fileprivate var pairs: [Pair<YAMLNode>]
    var tag: YAMLTag
    var style: Style
    var mark: YAMLMark?

    enum Style: UInt32 { // swiftlint:disable:this nesting
      /// Let the emitter choose the style.
      case any
      /// The block mapping style.
      case block
      /// The flow mapping style.
      case flow
    }

    init(_ pairs: [(YAMLNode, YAMLNode)],
                _ tag: YAMLTag = .implicit,
                _ style: Style = .any,
                _ mark: YAMLMark? = nil) {
      self.pairs = pairs.map { Pair($0.0, $0.1) }
      self.tag = tag
      self.style = style
      self.mark = mark
    }
  }

  var mapping: Mapping? {
    get {
      if case let .mapping(mapping) = self {
        return mapping
      }
      return nil
    }
    set {
      if let newValue = newValue {
        self = .mapping(newValue)
      }
    }
  }
}

extension YAMLNode.Mapping: Comparable {
  static func < (lhs: YAMLNode.Mapping, rhs: YAMLNode.Mapping) -> Bool {
    return lhs.pairs < rhs.pairs
  }
}

extension YAMLNode.Mapping: Equatable {
  static func == (lhs: YAMLNode.Mapping, rhs: YAMLNode.Mapping) -> Bool {
    return lhs.pairs == rhs.pairs && lhs.resolvedYAMLTag == rhs.resolvedYAMLTag
  }
}

extension YAMLNode.Mapping: ExpressibleByDictionaryLiteral {
  init(dictionaryLiteral elements: (YAMLNode, YAMLNode)...) {
    self.init(elements)
  }
}

extension YAMLNode.Mapping: MutableCollection {
  typealias Element = (key: YAMLNode, value: YAMLNode)

  // Sequence
  func makeIterator() -> Array<Element>.Iterator {
    let iterator = pairs.map(Pair.toTuple).makeIterator()
    return iterator
  }

  // Collection
  typealias Index = Array<Element>.Index

  var startIndex: Index {
    return pairs.startIndex
  }

  var endIndex: Index {
    return pairs.endIndex
  }

  func index(after index: Index) -> Index {
    return pairs.index(after: index)
  }

  subscript(index: Index) -> Element {
    get {
      return (key: pairs[index].key, value: pairs[index].value)
    }
    // MutableCollection
    set {
      pairs[index] = Pair(newValue.key, newValue.value)
    }
  }
}

extension YAMLNode.Mapping: YAMLTagResolvable {
  static let defaultYAMLTagName = YAMLTag.Name.map
}

extension YAMLNode.Mapping {
  var keys: LazyMapCollection<YAMLNode.Mapping, YAMLNode> {
    return lazy.map { $0.key }
  }

  var values: LazyMapCollection<YAMLNode.Mapping, YAMLNode> {
    return lazy.map { $0.value }
  }

  subscript(string: String) -> YAMLNode? {
    get {
      return self[YAMLNode(string)]
    }
    set {
      self[YAMLNode(string)] = newValue
    }
  }

  subscript(node: YAMLNode) -> YAMLNode? {
    get {
      let v = pairs.reversed().first(where: { $0.key == node })
      return v?.value
    }
    set {
      if let newValue = newValue {
        if let index = index(forKey: node) {
          pairs[index] = Pair(pairs[index].key, newValue)
        } else {
          pairs.append(Pair(node, newValue))
        }
      } else {
        if let index = index(forKey: node) {
          pairs.remove(at: index)
        }
      }
    }
  }

  func index(forKey key: YAMLNode) -> Index? {
    return pairs.reversed().index(where: { $0.key == key }).map({ pairs.index(before: $0.base) })
  }
}

private struct Pair<Value: Comparable & Equatable>: Comparable, Equatable {
  let key: Value
  let value: Value

  init(_ key: Value, _ value: Value) {
    self.key = key
    self.value = value
  }

  static func == (lhs: Pair, rhs: Pair) -> Bool {
    return lhs.key == rhs.key && lhs.value == rhs.value
  }

  static func < (lhs: Pair<Value>, rhs: Pair<Value>) -> Bool {
    return lhs.key < rhs.key
  }

  static func toTuple(pair: Pair) -> (key: Value, value: Value) {
    return (key: pair.key, value: pair.value)
  }
}


extension YAMLNode {
  struct Sequence {
    fileprivate var nodes: [YAMLNode]
    var tag: YAMLTag
    var style: Style
    var mark: YAMLMark?

    enum Style: UInt32 { // swiftlint:disable:this nesting
      /// Let the emitter choose the style.
      case any
      /// The block sequence style.
      case block
      /// The flow sequence style.
      case flow
    }

    init(_ nodes: [YAMLNode],
                _ tag: YAMLTag = .implicit,
                _ style: Style = .any,
                _ mark: YAMLMark? = nil) {
      self.nodes = nodes
      self.tag = tag
      self.style = style
      self.mark = mark
    }
  }

  var sequence: Sequence? {
    get {
      if case let .sequence(sequence) = self {
        return sequence
      }
      return nil
    }
    set {
      if let newValue = newValue {
        self = .sequence(newValue)
      }
    }
  }
}

// MARK: - YAMLNode.Sequence

extension YAMLNode.Sequence: Comparable {
  static func < (lhs: YAMLNode.Sequence, rhs: YAMLNode.Sequence) -> Bool {
    return lhs.nodes < rhs.nodes
  }
}

extension YAMLNode.Sequence: Equatable {
  static func == (lhs: YAMLNode.Sequence, rhs: YAMLNode.Sequence) -> Bool {
    return lhs.nodes == rhs.nodes && lhs.resolvedYAMLTag == rhs.resolvedYAMLTag
  }
}

extension YAMLNode.Sequence: ExpressibleByArrayLiteral {
  init(arrayLiteral elements: YAMLNode...) {
    self.init(elements)
  }
}

extension YAMLNode.Sequence: MutableCollection {
  // Sequence
  func makeIterator() -> Array<YAMLNode>.Iterator {
    return nodes.makeIterator()
  }

  // Collection
  typealias Index = Array<YAMLNode>.Index

  var startIndex: Index {
    return nodes.startIndex
  }

  var endIndex: Index {
    return nodes.endIndex
  }

  func index(after index: Index) -> Index {
    return nodes.index(after: index)
  }

  subscript(index: Index) -> YAMLNode {
    get {
      return nodes[index]
    }
    // MutableCollection
    set {
      nodes[index] = newValue
    }
  }

  subscript(bounds: Range<Index>) -> Array<YAMLNode>.SubSequence {
    get {
      return nodes[bounds]
    }
    // MutableCollection
    set {
      nodes[bounds] = newValue
    }
  }

  var indices: Array<YAMLNode>.Indices {
    return nodes.indices
  }
}

extension YAMLNode.Sequence: RandomAccessCollection {
  // BidirectionalCollection
  func index(before index: Index) -> Index {
    return nodes.index(before: index)
  }

  // RandomAccessCollection
  func index(_ index: Index, offsetBy num: Int) -> Index {
    return nodes.index(index, offsetBy: num)
  }

  func distance(from start: Index, to end: Int) -> Index {
    return nodes.distance(from: start, to: end)
  }
}

extension YAMLNode.Sequence: RangeReplaceableCollection {
  init() {
    self.init([])
  }

  mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C)
    where C: Collection, C.Iterator.Element == YAMLNode {
      nodes.replaceSubrange(subrange, with: newElements)
  }
}

extension YAMLNode.Sequence: YAMLTagResolvable {
  static let defaultYAMLTagName = YAMLTag.Name.seq
}


/// Parse all YAML documents in a String
func load_all(yaml: String,
                     _ resolver: YAMLResolver = .default,
                     _ constructor: YAMLConstructor = .default) throws -> YamlSequence<Any> {
  let parser = try YAMLParser(yaml: yaml, resolver: resolver, constructor: constructor)
  return YamlSequence { try parser.nextRoot()?.any }
}

/// Parse the first YAML document in a String
func load(yaml: String,
                 _ resolver: YAMLResolver = .default,
                 _ constructor: YAMLConstructor = .default) throws -> Any? {
  return try YAMLParser(yaml: yaml, resolver: resolver, constructor: constructor).singleRoot()?.any
}

/// Parse all YAML documents in a String
func compose_all(yaml: String,
                        _ resolver: YAMLResolver = .default,
                        _ constructor: YAMLConstructor = .default)
  throws -> YamlSequence<YAMLNode> {
  let parser = try YAMLParser(yaml: yaml, resolver: resolver, constructor: constructor)
  return YamlSequence(parser.nextRoot)
}

/// Parse the first YAML document in a String
func compose(yaml: String,
                    _ resolver: YAMLResolver = .default,
                    _ constructor: YAMLConstructor = .default) throws -> YAMLNode? {
  return try YAMLParser(yaml: yaml, resolver: resolver, constructor: constructor).singleRoot()
}

/// Sequence that holds error
struct YamlSequence<T>: Sequence, IteratorProtocol {
  private(set) var error: Swift.Error?

  mutating func next() -> T? {
    do {
      return try closure()
    } catch {
      self.error = error
      return nil
    }
  }

  fileprivate init(_ closure: @escaping () throws -> T?) {
    self.closure = closure
  }

  private let closure: () throws -> T?
}

final class YAMLParser {
  // MARK: public
  let yaml: String
  let resolver: YAMLResolver
  let constructor: YAMLConstructor

  /// Set up YAMLParser.
  init(yaml string: String,
              resolver: YAMLResolver = .default,
              constructor: YAMLConstructor = .default) throws {
    yaml = string
    self.resolver = resolver
    self.constructor = constructor

    yaml_parser_initialize(&parser)
    #if USE_UTF8
      yaml_parser_set_encoding(&parser, YAML_UTF8_ENCODING)
      utf8CString = string.utf8CString
      utf8CString.withUnsafeBytes { bytes in
        let input = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self)
        yaml_parser_set_input_string(&parser, input, bytes.count - 1)
      }
    #else
      // use native endian
      let isLittleEndian = 1 == 1.littleEndian
      yaml_parser_set_encoding(&parser, isLittleEndian
        ? YAML_UTF16LE_ENCODING : YAML_UTF16BE_ENCODING)
      let encoding: String.Encoding = isLittleEndian ? .utf16LittleEndian : .utf16BigEndian
      data = yaml.data(using: encoding)!
      data.withUnsafeBytes { bytes in
        yaml_parser_set_input_string(&parser, bytes, data.count)
      }
    #endif
    try parse() // Drop YAML_STREAM_START_EVENT
  }

  deinit {
    yaml_parser_delete(&parser)
  }

  /// Parse next document and return root YAMLNode.
  func nextRoot() throws -> YAMLNode? {
    guard !streamEndProduced, try parse().type != YAML_STREAM_END_EVENT else { return nil }
    return try loadDocument()
  }

  func singleRoot() throws -> YAMLNode? {
    guard !streamEndProduced, try parse().type != YAML_STREAM_END_EVENT else { return nil }
    let node = try loadDocument()
    let event = try parse()
    if event.type != YAML_STREAM_END_EVENT {
      throw YAMLError.composer(
        context: YAMLError.Context(text: "expected a single document in the stream",
                                   mark: YAMLMark(line: 1, column: 1)),
        problem: "but found another document", event.startYAMLMark,
        yaml: yaml
      )
    }
    return node
  }

  // MARK: private
  fileprivate var anchors = [String: YAMLNode]()
  fileprivate var parser = yaml_parser_t()
  #if USE_UTF8
  private let utf8CString: ContiguousArray<CChar>
  #else
  private let data: Data
  #endif
}

// MARK: implementation details
extension YAMLParser {
  fileprivate var streamEndProduced: Bool {
    return parser.stream_end_produced != 0
  }

  fileprivate func loadDocument() throws -> YAMLNode {
    let node = try loadYAMLNode(from: parse())
    try parse() // Drop YAML_DOCUMENT_END_EVENT
    return node
  }

  private func loadYAMLNode(from event: YAMLEvent) throws -> YAMLNode {
    switch event.type {
    case YAML_ALIAS_EVENT:
      return try loadAlias(from: event)
    case YAML_SCALAR_EVENT:
      return try loadScalar(from: event)
    case YAML_SEQUENCE_START_EVENT:
      return try loadSequence(from: event)
    case YAML_MAPPING_START_EVENT:
      return try loadMapping(from: event)
    default:
      fatalError("unreachable")
    }
  }

  @discardableResult
  fileprivate func parse() throws -> YAMLEvent {
    let event = YAMLEvent()
    guard yaml_parser_parse(&parser, &event.event) == 1 else {
      throw YAMLError(from: parser, with: yaml)
    }
    return event
  }

  private func loadAlias(from event: YAMLEvent) throws -> YAMLNode {
    guard let alias = event.aliasAnchor else {
      fatalError("unreachable")
    }
    guard let node = anchors[alias] else {
      throw YAMLError.composer(context: nil,
                               problem: "found undefined alias", event.startYAMLMark,
                               yaml: yaml)
    }
    return node
  }

  private func loadScalar(from event: YAMLEvent) throws -> YAMLNode {
    let node = YAMLNode.scalar(
      .init(event.scalarValue, tag(event.scalarYAMLTag), event.scalarStyle, event.startYAMLMark))
    if let anchor = event.scalarAnchor {
      anchors[anchor] = node
    }
    return node
  }

  private func loadSequence(from firstYAMLEvent: YAMLEvent) throws -> YAMLNode {
    var array = [YAMLNode]()
    var event = try parse()
    while event.type != YAML_SEQUENCE_END_EVENT {
      array.append(try loadYAMLNode(from: event))
      event = try parse()
    }
    let node = YAMLNode.sequence(.init(array,
                                       tag(firstYAMLEvent.sequenceYAMLTag),
                                       event.sequenceStyle, event.startYAMLMark))
    if let anchor = firstYAMLEvent.sequenceAnchor {
      anchors[anchor] = node
    }
    return node
  }

  private func loadMapping(from firstYAMLEvent: YAMLEvent) throws -> YAMLNode {
    var pairs = [(YAMLNode, YAMLNode)]()
    var event = try parse()
    while event.type != YAML_MAPPING_END_EVENT {
      let key = try loadYAMLNode(from: event)
      event = try parse()
      let value = try loadYAMLNode(from: event)
      pairs.append((key, value))
      event = try parse()
    }
    let node = YAMLNode.mapping(.init(pairs,
                                      tag(firstYAMLEvent.mappingYAMLTag),
                                      event.mappingStyle, event.startYAMLMark))
    if let anchor = firstYAMLEvent.mappingAnchor {
      anchors[anchor] = node
    }
    return node
  }

  private func tag(_ string: String?) -> YAMLTag {
    let tagName = string.map(YAMLTag.Name.init(rawValue:)) ?? .implicit
    return YAMLTag(tagName, resolver, constructor)
  }
}

/// Representation of `yaml_event_t`
private class YAMLEvent {
  var event = yaml_event_t()
  deinit { yaml_event_delete(&event) }

  var type: yaml_event_type_t {
    return event.type
  }

  // alias
  var aliasAnchor: String? {
    return string(from: event.data.alias.anchor)
  }

  // scalar
  var scalarAnchor: String? {
    return string(from: event.data.scalar.anchor)
  }
  var scalarStyle: YAMLNode.Scalar.Style {
    // swiftlint:disable:next force_unwrapping
    return YAMLNode.Scalar.Style(rawValue: event.data.scalar.style.rawValue)!
  }
  var scalarYAMLTag: String? {
    guard event.data.scalar.plain_implicit == 0,
      event.data.scalar.quoted_implicit == 0 else {
        return nil
    }
    return string(from: event.data.scalar.tag)
  }
  var scalarValue: String {
    // scalar may contain NULL characters
    let buffer = UnsafeBufferPointer(start: event.data.scalar.value,
                                     count: event.data.scalar.length)
    // libYAML converts scalar characters into UTF8 if input is other than YAML_UTF8_ENCODING
    return String(bytes: buffer, encoding: .utf8)!
  }

  // sequence
  var sequenceAnchor: String? {
    return string(from: event.data.sequence_start.anchor)
  }
  var sequenceStyle: YAMLNode.Sequence.Style {
    // swiftlint:disable:next force_unwrapping
    return YAMLNode.Sequence.Style(rawValue: event.data.sequence_start.style.rawValue)!
  }
  var sequenceYAMLTag: String? {
    return event.data.sequence_start.implicit != 0
      ? nil : string(from: event.data.sequence_start.tag)
  }

  // mapping
  var mappingAnchor: String? {
    return string(from: event.data.scalar.anchor)
  }
  var mappingStyle: YAMLNode.Mapping.Style {
    // swiftlint:disable:next force_unwrapping
    return YAMLNode.Mapping.Style(rawValue: event.data.mapping_start.style.rawValue)!
  }
  var mappingYAMLTag: String? {
    return event.data.mapping_start.implicit != 0
      ? nil : string(from: event.data.sequence_start.tag)
  }

  // start_mark
  var startYAMLMark: YAMLMark {
    return YAMLMark(line: event.start_mark.line + 1, column: event.start_mark.column + 1)
  }
}
private func string(from pointer: UnsafePointer<UInt8>!) -> String? {
  return String.decodeCString(pointer, as: UTF8.self, repairingInvalidCodeUnits: true)?.result
}


extension YAMLNode {
  /// initialize `YAMLNode` with instance of `YAMLNodeRepresentable`
  /// - Parameter representable: instance of `YAMLNodeRepresentable`
  /// - Throws: `YAMLError`
  init<T: YAMLNodeRepresentable>(_ representable: T) throws {
    self = try representable.represented()
  }
}

// MARK: - YAMLNodeRepresentable
/// Type is representabe as `YAMLNode`
protocol YAMLNodeRepresentable {
  func represented() throws -> YAMLNode
}

extension YAMLNode: YAMLNodeRepresentable {
  func represented() throws -> YAMLNode {
    return self
  }
}

extension Array: YAMLNodeRepresentable {
  func represented() throws -> YAMLNode {
    let nodes = try map(represent)
    return YAMLNode(nodes, YAMLTag(.seq))
  }
}

extension Dictionary: YAMLNodeRepresentable {
  func represented() throws -> YAMLNode {
    let pairs = try map { (key: try represent($0.0), value: try represent($0.1)) }
    return YAMLNode(pairs.sorted { $0.key < $1.key }, YAMLTag(.map))
  }
}

private func represent(_ value: Any) throws -> YAMLNode {
  if let string = value as? String {
    return YAMLNode(string)
  } else if let representable = value as? YAMLNodeRepresentable {
    return try representable.represented()
  }
  throw YAMLError.representer(problem: "Failed to represent \(value)")
}

// MARK: - ScalarRepresentable
/// Type is representabe as `YAMLNode.scalar`
protocol ScalarRepresentable: YAMLNodeRepresentable {}

extension Bool: ScalarRepresentable {
  func represented() throws -> YAMLNode {
    return YAMLNode(self ? "true" : "false", YAMLTag(.bool))
  }
}

extension Data: ScalarRepresentable {
  func represented() throws -> YAMLNode {
    return YAMLNode(base64EncodedString(), YAMLTag(.binary))
  }
}

extension Date: ScalarRepresentable {
  func represented() throws -> YAMLNode {
    return YAMLNode(iso8601String, YAMLTag(.timestamp))
  }

  private var iso8601String: String {
    let calendar = Calendar(identifier: .gregorian)
    let nanosecond = calendar.component(.nanosecond, from: self)
    #if os(Linux)
      // swift-corelibs-foundation has bug with nanosecond.
      // https://bugs.swift.org/browse/SR-3158
      return iso8601Formatter.string(from: self)
    #else
      if nanosecond != 0 {
        return iso8601WithFractionalSecondFormatter.string(from: self)
          .trimmingCharacters(in: characterSetZero) + "Z"
      } else {
        return iso8601Formatter.string(from: self)
      }
    #endif
  }

  fileprivate var iso8601StringWithFullNanosecond: String {
    let calendar = Calendar(identifier: .gregorian)
    let nanosecond = calendar.component(.nanosecond, from: self)
    if nanosecond != 0 {
      return iso8601WithoutZFormatter.string(from: self) +
        String(format: ".%09d", nanosecond).trimmingCharacters(in: characterSetZero) + "Z"
    } else {
      return iso8601Formatter.string(from: self)
    }
  }
}

private let characterSetZero = CharacterSet(charactersIn: "0")

private let iso8601Formatter: DateFormatter = {
  var formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  return formatter
}()

private let iso8601WithoutZFormatter: DateFormatter = {
  var formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss"
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  return formatter
}()

// DateFormatter truncates Fractional Second to 10^-4
private let iso8601WithFractionalSecondFormatter: DateFormatter = {
  var formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSS"
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  return formatter
}()

extension Double: ScalarRepresentable {
  func represented() throws -> YAMLNode {
    return YAMLNode(doubleFormatter.string(for: self)!
      .replacingOccurrences(of: "+-", with: "-"), YAMLTag(.float))
  }
}

extension Float: ScalarRepresentable {
  func represented() throws -> YAMLNode {
    return YAMLNode(floatFormatter.string(for: self)!
      .replacingOccurrences(of: "+-", with: "-"), YAMLTag(.float))
  }
}

private func numberFormatter(with significantDigits: Int) -> NumberFormatter {
  let formatter = NumberFormatter()
  formatter.locale = Locale(identifier: "en_US")
  formatter.numberStyle = .scientific
  formatter.usesSignificantDigits = true
  formatter.maximumSignificantDigits = significantDigits
  formatter.positiveInfinitySymbol = ".inf"
  formatter.negativeInfinitySymbol = "-.inf"
  formatter.notANumberSymbol = ".nan"
  formatter.exponentSymbol = "e+"
  return formatter
}

private let doubleFormatter = numberFormatter(with: 15)
private let floatFormatter = numberFormatter(with: 7)

// TODO: Support `Float80`
//extension Float80: ScalarRepresentable {}

extension BinaryInteger {
  func represented() throws -> YAMLNode {
    return YAMLNode(String(describing: self), YAMLTag(.int))
  }
}

extension Int: ScalarRepresentable {}
extension Int16: ScalarRepresentable {}
extension Int32: ScalarRepresentable {}
extension Int64: ScalarRepresentable {}
extension Int8: ScalarRepresentable {}
extension UInt: ScalarRepresentable {}
extension UInt16: ScalarRepresentable {}
extension UInt32: ScalarRepresentable {}
extension UInt64: ScalarRepresentable {}
extension UInt8: ScalarRepresentable {}

extension Optional: YAMLNodeRepresentable {
  func represented() throws -> YAMLNode {
    switch self {
    case let .some(wrapped):
      return try represent(wrapped)
    case .none:
      return YAMLNode("null", YAMLTag(.null))
    }
  }
}

extension Decimal: ScalarRepresentable {
  func represented() throws -> YAMLNode {
    return YAMLNode(description)
  }
}

extension URL: ScalarRepresentable {
  func represented() throws -> YAMLNode {
    return YAMLNode(absoluteString)
  }
}

/// MARK: - ScalarRepresentableCustomizedForCodable

protocol ScalarRepresentableCustomizedForCodable: ScalarRepresentable {
  func representedForCodable() -> YAMLNode
}

extension Date: ScalarRepresentableCustomizedForCodable {
  func representedForCodable() -> YAMLNode {
    return YAMLNode(iso8601StringWithFullNanosecond, YAMLTag(.timestamp))
  }
}

extension Double: ScalarRepresentableCustomizedForCodable {}
extension Float: ScalarRepresentableCustomizedForCodable {}

extension FloatingPoint where Self: CVarArg {
  func representedForCodable() -> YAMLNode {
    return YAMLNode(formattedStringForCodable, YAMLTag(.float))
  }

  private var formattedStringForCodable: String {
    // Since `NumberFormatter` creates a string with insufficient precision for Decode,
    // it uses with `String(format:...)`
    #if os(Linux)
      let DBL_DECIMAL_DIG = 17
    #endif
    let string = String(format: "%.*g", DBL_DECIMAL_DIG, self)
    // "%*.g" does not use scientific notation if the exponent is less than –4.
    // So fallback to using `NumberFormatter` if string does not uses scientific notation.
    guard string.lazy.suffix(5).contains("e") else {
      return doubleFormatter.string(for: self)!.replacingOccurrences(of: "+-", with: "-")
    }
    return string
  }
}

final class YAMLResolver {
  struct Rule {
    let tag: YAMLTag.Name
    let regexp: NSRegularExpression
    var pattern: String { return regexp.pattern }

    init(_ tag: YAMLTag.Name, _ pattern: String) throws {
      self.tag = tag
      self.regexp = try .init(pattern: pattern, options: [])
    }
  }

  let rules: [Rule]

  init(_ rules: [Rule] = []) { self.rules = rules }

  func resolveYAMLTag(of node: YAMLNode) -> YAMLTag.Name {
    switch node {
    case let .scalar(scalar):
      return resolveYAMLTag(of: scalar)
    case let .mapping(mapping):
      return resolveYAMLTag(of: mapping)
    case let .sequence(sequence):
      return resolveYAMLTag(of: sequence)
    }
  }

  /// Returns a YAMLResolver constructed by appending rule.
  func appending(_ rule: Rule) -> YAMLResolver {
    return .init(rules + [rule])
  }

  /// Returns a YAMLResolver constructed by appending pattern for tag.
  func appending(_ tag: YAMLTag.Name, _ pattern: String) throws -> YAMLResolver {
    return appending(try Rule(tag, pattern))
  }

  /// Returns a YAMLResolver constructed by replacing rule.
  func replacing(_ rule: Rule) -> YAMLResolver {
    return .init(rules.map { $0.tag == rule.tag ? rule : $0 })
  }

  /// Returns a YAMLResolver constructed by replacing pattern for tag.
  func replacing(_ tag: YAMLTag.Name, with pattern: String) throws -> YAMLResolver {
    return .init(try rules.map { $0.tag == tag ? try Rule($0.tag, pattern) : $0 })
  }

  /// Returns a YAMLResolver constructed by removing pattern for tag.
  func removing(_ tag: YAMLTag.Name) -> YAMLResolver {
    return .init(rules.filter({ $0.tag != tag }))
  }

  // MARK: - internal

  func resolveYAMLTag<T>(of value: T) -> YAMLTag.Name where T: YAMLTagResolvable {
    return value.resolveYAMLTag(using: self)
  }

  func resolveYAMLTag(from string: String) -> YAMLTag.Name {
    for rule in rules where rule.regexp.matches(in: string) {
      return rule.tag
    }
    return .str
  }
}

extension YAMLResolver {
  static let basic = YAMLResolver()
  static let `default` = YAMLResolver([
    .bool, .int, .float, .merge, .null, .timestamp, .value])
}

extension YAMLResolver.Rule {
  // swiftlint:disable:next force_try
  static let bool = try! YAMLResolver.Rule(.bool, """
      ^(?:yes|Yes|YES|no|No|NO\
      |true|True|TRUE|false|False|FALSE\
      |on|On|ON|off|Off|OFF)$
      """)
  // swiftlint:disable:next force_try
  static let int = try! YAMLResolver.Rule(.int, """
      ^(?:[-+]?0b[0-1_]+\
      |[-+]?0o?[0-7_]+\
      |[-+]?(?:0|[1-9][0-9_]*)\
      |[-+]?0x[0-9a-fA-F_]+\
      |[-+]?[1-9][0-9_]*(?::[0-5]?[0-9])+)$
      """)
  // swiftlint:disable:next force_try
  static let float = try! YAMLResolver.Rule(.float, """
      ^(?:[-+]?(?:[0-9][0-9_]*)(?:\\.[0-9_]*)?(?:[eE][-+]?[0-9]+)?\
      |\\.[0-9_]+(?:[eE][-+][0-9]+)?\
      |[-+]?[0-9][0-9_]*(?::[0-5]?[0-9])+\\.[0-9_]*\
      |[-+]?\\.(?:inf|Inf|INF)\
      |\\.(?:nan|NaN|NAN))$
      """)
  // swiftlint:disable:next force_try
  static let merge = try! YAMLResolver.Rule(.merge, "^(?:<<)$")
  // swiftlint:disable:next force_try
  static let null = try! YAMLResolver.Rule(.null, """
      ^(?:~\
      |null|Null|NULL\
      |)$
      """)
  // swiftlint:disable:next force_try
  static let timestamp = try! YAMLResolver.Rule(.timestamp, """
      ^(?:[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\
      |[0-9][0-9][0-9][0-9]-[0-9][0-9]?-[0-9][0-9]?\
      (?:[Tt]|[ \\t]+)[0-9][0-9]?\
      :[0-9][0-9]:[0-9][0-9](?:\\.[0-9]*)?\
      (?:[ \\t]*(?:Z|[-+][0-9][0-9]?(?::[0-9][0-9])?))?)$
      """)
  // swiftlint:disable:next force_try
  static let value = try! YAMLResolver.Rule(.value, "^(?:=)$")
}

func pattern(_ string: String) -> NSRegularExpression {
  do {
    return try .init(pattern: string, options: [])
  } catch {
    fatalError("unreachable")
  }
}

extension NSRegularExpression {
  fileprivate func matches(in string: String) -> Bool {
    let range = NSRange(location: 0, length: string.utf16.count)
    if let match = firstMatch(in: string, options: [], range: range) {
      return match.range.location != NSNotFound
    }
    return false
  }
}

extension String {
  typealias LineNumberColumnAndContents = (lineNumber: Int, column: Int, contents: String)

  /// line number, column and contents at utf8 offset.
  func utf8LineNumberColumnAndContents(at offset: Int) -> LineNumberColumnAndContents? {
    guard let index = utf8
      .index(utf8.startIndex, offsetBy: offset, limitedBy: utf8.endIndex)?
      .samePosition(in: self) else { return nil }
    return lineNumberColumnAndContents(at: index)
  }

  /// line number, column and contents at utf16 offset.
  func utf16LineNumberColumnAndContents(at offset: Int) -> LineNumberColumnAndContents? {
    guard let index = utf16
      .index(utf16.startIndex, offsetBy: offset, limitedBy: utf16.endIndex)?
      .samePosition(in: self) else { return nil }
    return lineNumberColumnAndContents(at: index)
  }

  /// line number, column and contents at Index.
  func lineNumberColumnAndContents(at index: Index) -> LineNumberColumnAndContents {
    assert((startIndex..<endIndex).contains(index))
    var number = 0
    var outStartIndex = startIndex, outEndIndex = startIndex, outContentsEndIndex = startIndex
    getLineStart(&outStartIndex, end: &outEndIndex, contentsEnd: &outContentsEndIndex,
                 for: startIndex..<startIndex)
    while outEndIndex <= index && outEndIndex < endIndex {
      number += 1
      let range: Range = outEndIndex..<outEndIndex
      getLineStart(&outStartIndex, end: &outEndIndex, contentsEnd: &outContentsEndIndex,
                   for: range)
    }
    let utf16StartIndex = outStartIndex.samePosition(in: utf16)!
    let utf16Index = index.samePosition(in: utf16)!
    return (
      number,
      utf16.distance(from: utf16StartIndex, to: utf16Index),
      String(self[outStartIndex..<outEndIndex])
    )
  }

  /// substring indicated by line number.
  func substring(at line: Int) -> String {
    var number = 0
    var outStartIndex = startIndex, outEndIndex = startIndex, outContentsEndIndex = startIndex
    getLineStart(&outStartIndex, end: &outEndIndex, contentsEnd: &outContentsEndIndex,
                 for: startIndex..<startIndex)
    while number < line && outEndIndex < endIndex {
      number += 1
      let range: Range = outEndIndex..<outEndIndex
      getLineStart(&outStartIndex, end: &outEndIndex, contentsEnd: &outContentsEndIndex,
                   for: range)
    }
    return String(self[outStartIndex..<outEndIndex])
  }

  /// String appending newline if is not ending with newline.
  var endingWithNewLine: String {
    let isEndsWithNewLines = unicodeScalars.last.map(CharacterSet.newlines.contains) ?? false
    if isEndsWithNewLines {
      return self
    } else {
      return self + "\n"
    }
  }
}
final class YAMLTag {
  struct Name: RawRepresentable {
    let rawValue: String
    init(rawValue: String) {
      self.rawValue = rawValue
    }
  }

  static var implicit: YAMLTag {
    return YAMLTag(.implicit)
  }

  // internal
  let constructor: YAMLConstructor
  var name: Name

  init(_ name: Name,
              _ resolver: YAMLResolver = .default,
              _ constructor: YAMLConstructor = .default) {
    self.resolver = resolver
    self.constructor = constructor
    self.name = name
  }

  func resolved<T>(with value: T) -> YAMLTag where T: YAMLTagResolvable {
    if name == .implicit {
      name = resolver.resolveYAMLTag(of: value)
    } else if name == .nonSpecific {
      name = T.defaultYAMLTagName
    }
    return self
  }

  // fileprivate
  fileprivate let resolver: YAMLResolver
}

extension YAMLTag: CustomStringConvertible {
  var description: String {
    return name.rawValue
  }
}

extension YAMLTag: Hashable {
  var hashValue: Int {
    return name.hashValue
  }

  static func == (lhs: YAMLTag, rhs: YAMLTag) -> Bool {
    return lhs.name == rhs.name
  }
}

extension YAMLTag.Name: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    self.rawValue = value
  }
}

extension YAMLTag.Name: Hashable {
  var hashValue: Int {
    return rawValue.hashValue
  }

  static func == (lhs: YAMLTag.Name, rhs: YAMLTag.Name) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
}

// http://www.yaml.org/spec/1.2/spec.html#Schema
extension YAMLTag.Name {
  // Special
  /// YAMLTag should be resolved by value.
  static let implicit: YAMLTag.Name = ""
  /// YAMLTag should not be resolved by value, and be resolved as .str, .seq or .map.
  static let nonSpecific: YAMLTag.Name = "!"

  // Failsafe Schema
  /// "tag:yaml.org,2002:str" <http://yaml.org/type/str.html>
  static let str: YAMLTag.Name = "tag:yaml.org,2002:str"
  /// "tag:yaml.org,2002:seq" <http://yaml.org/type/seq.html>
  static let seq: YAMLTag.Name  = "tag:yaml.org,2002:seq"
  /// "tag:yaml.org,2002:map" <http://yaml.org/type/map.html>
  static let map: YAMLTag.Name  = "tag:yaml.org,2002:map"
  // JSON Schema
  /// "tag:yaml.org,2002:bool" <http://yaml.org/type/bool.html>
  static let bool: YAMLTag.Name  = "tag:yaml.org,2002:bool"
  /// "tag:yaml.org,2002:float" <http://yaml.org/type/float.html>
  static let float: YAMLTag.Name  =  "tag:yaml.org,2002:float"
  /// "tag:yaml.org,2002:null" <http://yaml.org/type/null.html>
  static let null: YAMLTag.Name  = "tag:yaml.org,2002:null"
  /// "tag:yaml.org,2002:int" <http://yaml.org/type/int.html>
  static let int: YAMLTag.Name  = "tag:yaml.org,2002:int"
  // http://yaml.org/type/index.html
  /// "tag:yaml.org,2002:binary" <http://yaml.org/type/binary.html>
  static let binary: YAMLTag.Name  = "tag:yaml.org,2002:binary"
  /// "tag:yaml.org,2002:merge" <http://yaml.org/type/merge.html>
  static let merge: YAMLTag.Name  = "tag:yaml.org,2002:merge"
  /// "tag:yaml.org,2002:omap" <http://yaml.org/type/omap.html>
  static let omap: YAMLTag.Name  = "tag:yaml.org,2002:omap"
  /// "tag:yaml.org,2002:pairs" <http://yaml.org/type/pairs.html>
  static let pairs: YAMLTag.Name  = "tag:yaml.org,2002:pairs"
  /// "tag:yaml.org,2002:set". <http://yaml.org/type/set.html>
  static let set: YAMLTag.Name  = "tag:yaml.org,2002:set"
  /// "tag:yaml.org,2002:timestamp" <http://yaml.org/type/timestamp.html>
  static let timestamp: YAMLTag.Name  = "tag:yaml.org,2002:timestamp"
  /// "tag:yaml.org,2002:value" <http://yaml.org/type/value.html>
  static let value: YAMLTag.Name  = "tag:yaml.org,2002:value"
  /// "tag:yaml.org,2002:yaml" <http://yaml.org/type/yaml.html> We don't support this.
  static let yaml: YAMLTag.Name  = "tag:yaml.org,2002:yaml"
}

protocol YAMLTagResolvable {
  var tag: YAMLTag { get }
  static var defaultYAMLTagName: YAMLTag.Name { get }
  func resolveYAMLTag(using resolver: YAMLResolver) -> YAMLTag.Name
}

extension YAMLTagResolvable {
  var resolvedYAMLTag: YAMLTag {
    return tag.resolved(with: self)
  }

  func resolveYAMLTag(using resolver: YAMLResolver) -> YAMLTag.Name {
    return tag.name == .implicit ? Self.defaultYAMLTagName : tag.name
  }
}

enum YAMLError: Swift.Error {
  // Used in `yaml_emitter_t` and `yaml_parser_t`
  /// `YAML_NO_ERROR`. No error is produced.
  case no

  /// `YAML_MEMORY_ERROR`. Cannot allocate or reallocate a block of memory.
  case memory

  // Used in `yaml_parser_t`
  case reader(problem: String, byteOffset: Int, value: Int32, yaml: String)

  // line and column start from 1, column is counted by unicodeScalars
  case scanner(context: Context?, problem: String, YAMLMark, yaml: String)

  /// `YAML_PARSER_ERROR`. Cannot parse the input stream.
  case parser(context: Context?, problem: String, YAMLMark, yaml: String)

  /// `YAML_COMPOSER_ERROR`. Cannot compose a YAML document.
  case composer(context: Context?, problem: String, YAMLMark, yaml: String)

  // Used in `yaml_emitter_t`
  case writer(problem: String)

  /// `YAML_EMITTER_ERROR`. Cannot emit a YAML stream.
  case emitter(problem: String)

  /// Used in `YAMLNodeRepresentable`
  case representer(problem: String)

  /// The error context
  struct Context: CustomStringConvertible {
    /// error context
    let text: String
    /// context position
    let mark: YAMLMark
    /// A textual representation of this instance.
    var description: String {
      return text + " in line \(mark.line), column \(mark.column)\n"
    }
  }
}

extension YAMLError {
  init(from parser: yaml_parser_t, with yaml: String) {
    func context(from parser: yaml_parser_t) -> Context? {
      guard let context = parser.context else { return nil }
      return Context(
        text: String(cString: context),
        mark: YAMLMark(line: parser.context_mark.line + 1, column: parser.context_mark.column + 1)
      )
    }

    func problemYAMLMark(from parser: yaml_parser_t) -> YAMLMark {
      return YAMLMark(line: parser.problem_mark.line + 1, column: parser.problem_mark.column + 1)
    }

    switch parser.error {
    case YAML_MEMORY_ERROR:
      self = .memory
    case YAML_READER_ERROR:
      self = .reader(problem: String(cString: parser.problem),
                     byteOffset: parser.problem_offset,
                     value: parser.problem_value,
                     yaml: yaml)
    case YAML_SCANNER_ERROR:
      self = .scanner(context: context(from: parser),
                      problem: String(cString: parser.problem), problemYAMLMark(from: parser),
                      yaml: yaml)
    case YAML_PARSER_ERROR:
      self = .parser(context: context(from: parser),
                     problem: String(cString: parser.problem), problemYAMLMark(from: parser),
                     yaml: yaml)
    case YAML_COMPOSER_ERROR:
      self = .composer(context: context(from: parser),
                       problem: String(cString: parser.problem), problemYAMLMark(from: parser),
                       yaml: yaml)
    default:
      fatalError("YAMLParser has unknown error: \(parser.error)!")
    }
  }

  init(from emitter: yaml_emitter_t) {
    switch emitter.error {
    case YAML_MEMORY_ERROR:
      self = .memory
    case YAML_EMITTER_ERROR:
      self = .emitter(problem: String(cString: emitter.problem))
    default:
      fatalError("YAMLEmitter has unknown error: \(emitter.error)!")
    }
  }
}

extension YAMLError: CustomStringConvertible {
  /// A textual representation of this instance.
  var description: String {
    switch self {
    case .no:
      return "No error is produced"
    case .memory:
      return "Memory error"
    case let .reader(problem, byteOffset, value, yaml):
      guard let (mark, contents) = markAndSnippet(from: yaml, byteOffset)
        else { return "\(problem) at byte offset: \(byteOffset), value: \(value)" }
      return "\(mark): error: reader: \(problem):\n" + contents.endingWithNewLine
        + String(repeating: " ", count: mark.column - 1) + "^"
    case let .scanner(context, problem, mark, yaml):
      return "\(mark): error: scanner: \(context?.description ?? "")\(problem):\n"
        + mark.snippet(from: yaml)
    case let .parser(context, problem, mark, yaml):
      return "\(mark): error: parser: \(context?.description ?? "")\(problem):\n"
        + mark.snippet(from: yaml)
    case let .composer(context, problem, mark, yaml):
      return "\(mark): error: composer: \(context?.description ?? "")\(problem):\n"
        + mark.snippet(from: yaml)
    case let .writer(problem), let .emitter(problem), let .representer(problem):
      return problem
    }
  }
}

extension YAMLError {
  fileprivate func markAndSnippet(from yaml: String, _ byteOffset: Int) -> (YAMLMark, String)? {
    #if USE_UTF8
      guard let (line, column, contents) = yaml.utf8LineNumberColumnAndContents(at: byteOffset)
        else { return nil }
    #else
      guard let (line, column, contents) = yaml.utf16LineNumberColumnAndContents(at: byteOffset / 2)
        else { return nil }
    #endif
    return (YAMLMark(line: line + 1, column: column + 1), contents)
  }
}
//#endif
