import Foundation
import JavaScriptCore

public class JSBridge {
  public private(set) var context: JSContext!
  private var index = 0
  private var nodes: [Int: UIJsFragmentNode] = [:]
  private var rootNodes: [String: UIJsFragmentNode] = [:]
  private var loadedPaths = Set<String>()
  public var debugRemoteUrl: String = "http://localhost:8000/"

  private func runFunction<P: Codable>(function: String,
                                       props: P?,
                                       canvasSize: CGSize) -> JSValue? {
    assert(Thread.isMainThread)
    guard let context = context else {
      return nil
    }
    var propsDictionary: Any = NSDictionary()
    if let props = props, !(props is UINilProps) {
      let jsonProps = try! JSONEncoder().encode(props)
      propsDictionary = try! JSONSerialization.jsonObject(with: jsonProps, options: [])
    }

    guard let jsfunction = context.objectForKeyedSubscript(function) else {
      print("'\(function)' not defined in js context.")
      return nil
    }

    let size: [String: CGFloat] = ["width": canvasSize.width, "height": canvasSize.height ]
    return jsfunction.call(withArguments: [propsDictionary, size])
  }

  /// Build a fragment by running the javacript function named *function*.
  /// - parameter function: The js function that will generate a function.
  /// - parameter props: The props that will be encoded and passed to the js render function.
  /// - parameter canvasSize: The size of the canvas bounding rect.
  public func buildFragment<P: UIPropsProtocol & Codable>(function: String,
                                                          props: P? = nil,
                                                          canvasSize: CGSize) -> UINodeProtocol {

    let fun = "ui_fragment_\(function)"
    if let idx = runFunction(function: fun, props: props, canvasSize: canvasSize)?.toNumber() {
      guard let node = nodes[idx.intValue] else {
        return UINilNode.nil
      }
      buildHierarchy(node: node)
      #if DEBUG
      node._debugPropsDescription =
        props?.reflectionDescription(del: UINodeInspectorDefaultDelimiters) ?? ""
      #endif
      return node
    }
    return UINilNode.nil
  }

  public enum Namespace: String { case palette, typography, flags, constants }

  /// Returns the value of the javascript variable named *name*.
  public func variable<T>(namespace: Namespace?, name: String) -> T? {
    assert(Thread.isMainThread)

    let prefix = namespace != nil ? "\(namespace!.rawValue)." : ""
    guard let jsvalue = context?.evaluateScript("\(prefix)\(name)") else { return nil }
    if let value = jsvalue.toObject() as? NSDictionary,
       let jsBrigeableValue = JSBridgeValue(dictionary: value) {
      return jsBrigeableValue.bridge() as? T
    }
    if jsvalue.isArray { return jsvalue.toArray() as? T }
    if jsvalue.isNumber { return jsvalue.toNumber() as? T }
    if jsvalue.isString { return jsvalue.toString() as? T }
    if jsvalue.isBoolean { return jsvalue.toBool() as? T }
    if jsvalue.isObject { return jsvalue.toObject() as? T}
    return nil
  }

  /// Resolve and apply a style computed by running the javacript function named *function*.
  /// - parameter view: The target view for this style.
  /// - parameter function: The js function that will generate a function.
  /// - parameter props: The props that will be encoded and passed to the js render function.
  /// - parameter canvasSize: The size of the canvas bounding rect.
  public func resolveStyle<P: UIPropsProtocol & Codable>(view: UIView,
                                                         function: String,
                                                         props: P? = nil,
                                                         canvasSize: CGSize) {
    let fun = "ui_style_\(function)"
    guard let value = runFunction(function: fun, props: props, canvasSize: canvasSize),
          let dictionary = value.toDictionary() as? [String : Any] else {
      return
    }
    let bridgedDictionary = self.bridgeDictionaryValues(dictionary)
    YGSet(view, bridgedDictionary)
  }

  // Builds the node hierarchy recursively.
  private func buildHierarchy(node: UIJsFragmentNode) {
    var children: [UIJsFragmentNode] = []
    for idx in node.jsChildrenIndices {
      guard let child = nodes[idx] else {
        continue
      }
      children.append(child)
    }
    node.children(children)
    for child in children {
      buildHierarchy(node: child)
    }
  }

  public init() {
    initJsContext()
  }

  private func loadFileFromRemoteServer(_ file: String) -> String? {
    guard let url = URL(string: "\(debugRemoteUrl)\(file).js") else { return nil }
    return try? String(contentsOf: url, encoding: .utf8)
  }

  private func loadFileFromBundle(_ file: String) -> String? {
    guard let path = Bundle.main.path(forResource: file, ofType: "js") else { return nil }
    return try? String(contentsOfFile: path, encoding: .utf8)
  }

  public func loadDefinition(file: String) {
    guard !loadedPaths.contains(file) else { return }
    let err = "Invalid js file \(file)."
    loadedPaths.insert(file)

    #if (arch(i386) || arch(x86_64)) && os(iOS)
      if let content = loadFileFromRemoteServer(file) {
        loadDefinition(source: content)
      } else if let content = loadFileFromBundle(file) {
        loadDefinition(source: content)
      } else {
        print(err)
      }
    #else
      if let content = loadFileFromBundle(file) {
        loadDefinition(source: content)
      } else {
        print(err)
      }
    #endif
  }

  /// Load fragments source code.
  public func loadDefinition(source: String) {
    let _ = evaluate(src: source)
  }

  /// Replaces the values that are *_JSBridge* compliant with their native bridge.
  private func bridgeDictionaryValues(_ dictionary: [String: Any]) -> [String: Any] {
    var result = dictionary
    for (key, value) in dictionary {
      if let value = value as? NSDictionary, let jsBrigeableValue = JSBridgeValue(dictionary: value) {
        result[key] = jsBrigeableValue.bridge()
      }
    }
    return result
  }

  private func evaluate(src: String) -> JSValue? {
    let escapedSrc = escapeNamespace(src: src)
    return context?.evaluateScript(escapedSrc)
  }

  /// Flatten ui.*.* definitions into ui_*_*
  private func escapeNamespace(src: String) -> String {
    func escapeUiNamespace(src: String, pattern: String) -> String {
      let regex = try! NSRegularExpression(pattern: "ui.([a-zA-Z]*).([a-zA-Z]*)", options: [])
      let matches = regex.matches(in: src,
                                  options: [],
                                  range: NSRange(location: 0, length: src.characters.count))

      var transformations: [String: String] = [:]
      for match in matches {
        var (original, reps): (String, [String]) = ("", [])
        for n in 0..<match.numberOfRanges {
          let substring = (src as NSString).substring(with: match.range(at: n))
          if substring.contains(".") {
            original = substring
          } else {
            reps.append(substring)
          }
        }
        let rep = reps.first!
        transformations[original] = original.replacingOccurrences(of: ".\(rep)", with: "_\(rep)")
      }
      return transformations.reduce(src, { $0.replacingOccurrences(of: $1.key, with: $1.value) })
    }
    var ret = src
    ret = escapeUiNamespace(src: ret, pattern: "ui.([a-zA-Z]*)")

    // Escape allowed nested namespaces.
    for nested in ["fragment", "style", "font"] {
      ret = ret.replacingOccurrences(of: "\(nested).", with: "\(nested)_")
    }
    return ret
  }

  /// Reset the javascript context.
  public func initJsContext() {
    context = JSContext()
    index = 0
    nodes = [:]
    /// The *Node(type: String, key: String, config: {}, children: [Node])* function, used in the
    /// javascript context to create a fragment node.
    let nodeBuild: @convention(block) (String, String?, NSDictionary, [NSNumber]) -> NSNumber = {
      type, key, dictionary, children in
      let nodeKey: String? = key == "undefined" || key == "null" ? nil : key
      let bridgedDictionary = self.bridgeDictionaryValues(dictionary as! [String : Any])
      let node = UIJsFragmentNode(key: nodeKey, create: {
        YGBuild(type) ?? UIView()
      }) { config in
        YGSet(config.view, bridgedDictionary)
      }
      // Keep tracks of the children nodes.
      node.jsChildrenIndices = children.map { $0.intValue }
      node.reuseIdentifier = type
      node._debugType = "\(type) (js fragment) "
      let index = self.index + 1
      self.index = index
      // Adds the created node to the pool of nodes.
      self.nodes[index] = node
      node.jsIndex = index
      return NSNumber(value: index)
    }
    let nodeBuildJSBridgeName: NSString = "Node"
    context?.setObject(nodeBuild, forKeyedSubscript: nodeBuildJSBridgeName)

    // js exeption handler.
    context?.exceptionHandler = { context, exception in
      print("js error: \(exception?.description ?? "unknown error")")
    }

    // Shortcuts for UIKit components name.
    for symbol in (YGUIKitSymbols() as! [NSString]) {
      context?.setObject(symbol, forKeyedSubscript: symbol)
    }

    context?.setObject(JSBridgeValue.Log.function,
                       forKeyedSubscript: JSBridgeValue.Log.functionName)
    context?.setObject(JSBridgeValue.Color.function,
                       forKeyedSubscript: JSBridgeValue.Color.functionName)
    context?.setObject(JSBridgeValue.Font.function,
                       forKeyedSubscript: JSBridgeValue.Font.functionName)

    _ = evaluate(src: JSBridgeValue.Color.initSrc)
    _ = evaluate(src: JSBridgeValue.Font.initSrc)
    _ = evaluate(src: JSBridgeValue.Yoga.initSrc)
    _ = evaluate(src: JSBridgeValue.UIKit.initSrc)

    let oldLoadedPaths = loadedPaths
    loadedPaths = Set<String>()
    for path in oldLoadedPaths {
      loadDefinition(file: path)
    }
  }
}

/// *UINode* subclass that is being created from the javascript context.
public class UIJsFragmentNode: UINode<UIView> {
  var jsChildrenIndices: [Int] = []
  var jsIndex: Int = 0
}

// MARK: - Internal

public struct JSBridgeValue {
  struct Key {
    static let marker = "_jsbridge"
    static let type = "_type"
    static let value = "_value"
  }

  /// The underlying dictionary.
  var dictionary: NSDictionary
  var type: NSString { return dictionary[Key.type] as! NSString }
  var value: [Any] { return dictionary[Key.value] as? [Any] ?? [] }

  /// Failable init method.
  init?(dictionary: NSDictionary) {
    guard dictionary[Key.marker] != nil else { return nil }
    self.dictionary = dictionary
  }

  func bridge() -> AnyObject {
    switch type {
    case Color.type:
      return Color.bridge(jsvalue: self)
    case Font.type:
      return Font.bridge(jsvalue: self)
    default:
      print("unbridgeable js type.")
      return NSObject()
    }
  }

  /// *color(hex: number, alpha: number)* function in the javascript context.
  public struct Color {
    static let type: NSString = "UIColor"
    static let functionName: NSString = "color"
    static let function: @convention(block) (Int, Int) -> NSDictionary = { rgb, alpha in
      let normalpha = alpha < 0 || alpha > 255 ? 255 : alpha
      let red = (rgb >> 16) & 0xff
      let green = (rgb >> 8) & 0xff
      let blue = rgb & 0xff

      var result = NSMutableDictionary()
      result[Key.marker] = true
      result[Key.type] = type
      result[Key.value] = [red, green, blue, normalpha]
      return result
    }
    public static func bridge(jsvalue: JSBridgeValue) -> UIColor {
      assert(jsvalue.type == Color.type)
      guard let components = jsvalue.value as? [Int], components.count == 4 else {
        print("malformed \(jsvalue.type) bridge value.")
        return .black
      }
      let rgba = components.map { CGFloat($0)/255.0 }
      return UIColor(red: rgba[0], green: rgba[1], blue: rgba[2], alpha: rgba[3])
    }
  }

  /// *log(message: string) function in the javascript context.
  struct Log {
    static let functionName: NSString = "log"
    static let function: @convention(block) (String) -> Void = { message in
      print("JSBRIDGE \(message)")
    }
  }
  /// *font(name: string, size: number, weight: number)* function in the javascript context.
  public struct Font {
    static let type: NSString = "UIFont"
    static let functionName: NSString = "font"
    static let function: @convention(block) (String, CGFloat, CGFloat) -> NSDictionary = {
      name, size, weight in
      var result = NSMutableDictionary()
      result[Key.marker] = true
      result[Key.type] = type
      result[Key.value] = [name, size, weight]
      return result
    }
    public static func bridge(jsvalue: JSBridgeValue) -> UIFont {
      assert(jsvalue.type == Font.type)
      let size = (jsvalue.value[1] as? CGFloat) ?? 12
      let name = (jsvalue.value[0] as? String) ?? "Arial"
      if name == "systemfont" {
        var weight = UIFont.Weight(rawValue: 0)
        if jsvalue.value.count == 3 {
          weight = UIFont.Weight(rawValue: jsvalue.value[2] as? CGFloat ?? 0)
        }
        return UIFont.systemFont(ofSize: size, weight: weight)
      } else {
        return UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
      }
    }
  }

  struct Yoga { }
  struct UIKit { }
}
