import Foundation
import JavaScriptCore

// MARK: - JSBridge

public class JSBridge {
  public private(set) var jsContext: JSContext!
  private let context: UIContextProtocol
  private var index = 0
  private var nodes: [Int: UIJsFragmentNode] = [:]
  private var rootNodes: [String: UIJsFragmentNode] = [:]
  private var loadedPaths = Set<String>()
  public var debugRemoteUrl: String = "http://localhost:8000/"
  public var prefetchedVars: [String: Any] = [:]

  private func runFunction<P: Codable>(function: String,
                                       props: P?,
                                       canvasSize: CGSize) -> JSValue? {
    assert(Thread.isMainThread)
    guard let context = jsContext else {
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
        props?.reflectionDescription(escape: UINodeInspectorDefaultDelimiters) ?? ""
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
    let fullKey = "\(prefix)\(name)"
    // If the variable belongs to one of the default namespaces, is prefetched and stored at
    // context initialization time.
    if let prefetchedVariable = prefetchedVars[fullKey] as? T {
      return prefetchedVariable
    }
    // Get the variable from the js context.
    guard let jsvalue = jsContext?.evaluateScript(fullKey) else { return nil }
    // If the jsvalue is a *JSBridgeValue* invoke the transformation.
    if let value = jsvalue.toObject() as? NSDictionary,
       let bridge = JSBridgeValue(dictionary: value){ return bridge.bridge() as? T }
    // The jsvalue is a simple scalar.
    if jsvalue.isArray { return jsvalue.toArray() as? T }
    if jsvalue.isNumber { return jsvalue.toNumber() as? T }
    if jsvalue.isString { return jsvalue.toString() as? T }
    if jsvalue.isBoolean { return jsvalue.toBool() as? T }
    if jsvalue.isObject { return jsvalue.toObject() as? T}
    return nil
  }

  private func prefetchVariables() {
    prefetchedVars = [:]
    let namespaces: [String] = [Namespace.palette.rawValue,
                                Namespace.typography.rawValue,
                                Namespace.flags.rawValue,
                                Namespace.constants.rawValue]
    // Prefetches the variables in the default namespaces.
    for namespace in namespaces {
      guard let jsdictionary = jsContext?.evaluateScript("\(namespace)").toDictionary() else {
        continue
      }
      for (key, obj) in jsdictionary {
        let fullKey = "\(namespace).\(key)"
        // For every entry it bridges the return value if necessary.
        if let obj = obj as? NSDictionary, let jsBrigeableValue = JSBridgeValue(dictionary: obj) {
          prefetchedVars[fullKey] = jsBrigeableValue.bridge()
        // The value is a simple scalar value.
        } else {
          prefetchedVars[fullKey] = obj
        }
      }
    }
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

  public init(context: UIContextProtocol) {
    self.context = context
    initJSContext()
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
      if let value = value as? NSDictionary, let jsbridge = JSBridgeValue(dictionary: value) {
        result[key] = jsbridge.bridge()
      }
    }
    return result
  }

  private func evaluate(src: String) -> JSValue? {
    let escapedSrc = escapeNamespace(src: src)
    return jsContext?.evaluateScript(escapedSrc)
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
  public func initJSContext() {
    jsContext = JSContext()
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
    let nodeBuildJSBridgeName: NSString = "UINode"
    jsContext?.setObject(nodeBuild, forKeyedSubscript: nodeBuildJSBridgeName)

    let screen: @convention(block) () -> NSDictionary = {
      let screenJson = try! JSONEncoder().encode(self.context.screen)
      let screenDictionary = try! JSONSerialization.jsonObject(with: screenJson, options: [])
      return screenDictionary as! NSDictionary
    }
    let screenJSBridgeName: NSString = "screen"
    jsContext?.setObject(screen, forKeyedSubscript: screenJSBridgeName)

    // js exeption handler.
    jsContext?.exceptionHandler = { context, exception in
      print("js error: \(exception?.description ?? "unknown error")")
    }

    // Shortcuts for UIKit components name.
    for symbol in (YGUIKitSymbols() as! [NSString]) {
      jsContext?.setObject(symbol, forKeyedSubscript: symbol)
    }
    jsContext?.setObject(JSBridgeValue.Log.function,
                       forKeyedSubscript: JSBridgeValue.Log.functionName)
    jsContext?.setObject(JSBridgeValue.Color.function,
                       forKeyedSubscript: JSBridgeValue.Color.functionName)
    jsContext?.setObject(JSBridgeValue.Font.function,
                       forKeyedSubscript: JSBridgeValue.Font.functionName)
    jsContext?.setObject(JSBridgeValue.Size.function,
                       forKeyedSubscript: JSBridgeValue.Size.functionName)
    jsContext?.setObject(JSBridgeValue.Image.function,
                       forKeyedSubscript: JSBridgeValue.Image.functionName)
    jsContext?.setObject(JSBridgeValue.URL.function,
                       forKeyedSubscript: JSBridgeValue.URL.functionName)

    _ = evaluate(src: JSBridgeValue.Color.initSrc)
    _ = evaluate(src: JSBridgeValue.Font.initSrc)
    _ = evaluate(src: JSBridgeValue.Yoga.initSrc)
    _ = evaluate(src: JSBridgeValue.UIKit.initSrc)

    // Reloads all of the definitions previously loaded.
    let oldLoadedPaths = loadedPaths
    loadedPaths = Set<String>()
    // Stylesheet is the global default path loaded (if available).
    loadDefinition(file: "stylesheet")
    for path in oldLoadedPaths {
      loadDefinition(file: path)
    }
    // Prefetches all of the variables that are defined in the default namespaces.
    prefetchVariables()
  }
}

/// *UINode* subclass that is being created from the javascript context.
public class UIJsFragmentNode: UINode<UIView> {
  var jsChildrenIndices: [Int] = []
  var jsIndex: Int = 0
}

// MARK: - JSBridgeValueInternal

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
    case Size.type:
      return Size.bridge(jsvalue: self)
    case Image.type:
      return Image.bridge(jsvalue: self)
    case URL.type:
      return URL.bridge(jsvalue: self)
    default:
      print("unbridgeable js type.")
      return NSObject()
    }
  }

  /// *color(hex: number, alpha: number)* function in the javascript context.
  public struct Color {
    static let type: NSString = "UIColor"
    static let functionName: NSString = "color"
    static let function: @convention(block) (Int) -> NSDictionary = { rgb in
      let red = (rgb >> 16) & 0xff
      let green = (rgb >> 8) & 0xff
      let blue = rgb & 0xff
      return makeBridgeableDictionary(type, [red, green, blue, 255])
    }
    public static func bridge(jsvalue: JSBridgeValue) -> UIColor {
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
      return makeBridgeableDictionary(type, [name, size, weight])

    }
    public static func bridge(jsvalue: JSBridgeValue) -> UIFont {
      let systemfont = "systemfont"
      let size: CGFloat = cast(jsvalue, at: 1, fallback: 12)
      let name = cast(jsvalue, at: 0, fallback: systemfont)
      if name == systemfont {
        var weight = UIFont.Weight(rawValue: 0)
        if jsvalue.value.count == 3 {
          weight = UIFont.Weight(rawValue: cast(jsvalue, at: 2, fallback: 0))
        }
        return UIFont.systemFont(ofSize: size, weight: weight)
      } else {
        return UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
      }
    }
  }

  /// *size(width: number, height: number)* function in the javascript context.
  public struct Size {
    static let type: NSString = "CGSize"
    static let functionName: NSString = "size"
    static let function: @convention(block) (String, CGFloat) -> NSDictionary = { width, heigth in
      return makeBridgeableDictionary(type, [width, heigth])
    }
    public static func bridge(jsvalue: JSBridgeValue) -> NSValue {
      return NSValue(cgSize: CGSize(width: cast(jsvalue, at: 0, fallback: 0),
                                    height: cast(jsvalue, at: 1, fallback: 0)))
    }
  }

  /// *image(name: string)* function in the javascript context.
  public struct Image {
    static let type: NSString = "UIImage"
    static let functionName: NSString = "image"
    static let function: @convention(block) (String) -> NSDictionary = { name in
      return makeBridgeableDictionary(type, [name])
    }
    public static func bridge(jsvalue: JSBridgeValue) -> UIImage {
      return UIImage(named: cast(jsvalue, at: 0, fallback: String())) ?? UIImage()
    }
  }

  /// *url(url: string)* function in the javascript context.
  public struct URL {
    static let type: NSString = "NSURL"
    static let functionName: NSString = "url"
    static let function: @convention(block) (String) -> NSDictionary = { path in
      return makeBridgeableDictionary(type, [path])
    }
    public static func bridge(jsvalue: JSBridgeValue) -> NSURL {
      return NSURL(string: cast(jsvalue, at: 0, fallback: String())) ?? NSURL()
    }
  }

  // Make a well-formatted bridge dicitonary.
  private static func makeBridgeableDictionary(_ type: NSString, _ value: [Any]) -> NSDictionary {
    let result = NSMutableDictionary()
    result[Key.marker] = true
    result[Key.type] = type
    result[Key.value] = value
    return result
  }

  // Returns the value at the index of the bridge jsvalue array casted accordingly.
  private static func cast<T>(_ jsvalue: JSBridgeValue, at index: Int, fallback: T) -> T {
    return jsvalue.value[index] as? T ?? fallback
  }

  struct Yoga { }
  struct UIKit { }
}

//MARK: - Constants

extension JSBridgeValue.Color {
  static var initSrc: String {
    return """
    const ui.color = { aliceblue: 0xf0f8ff, antiquewhite: 0xfaebd7, aqua: 0x00ffff,
      aquamarine: 0x7fffd4, azure: 0xf0ffff, beige: 0xf5f5dc, bisque: 0xffe4c4, black: 0x000000,
      blanchedalmond: 0xffebcd, blue: 0x0000ff, blueviolet: 0x8a2be2, brown: 0xa52a2a,
      burlywood: 0xdeb887, cadetblue: 0x5f9ea0, chartreuse: 0x7fff00, chocolate: 0xd2691e,
      coral: 0xff7f50, cornflowerblue: 0x6495ed, cornsilk: 0xfff8dc, crimson: 0xdc143c,
      cyan: 0x00ffff, darkblue: 0x00008b, darkcyan: 0x008b8b, darkgoldenrod: 0xb8860b,
      darkgray: 0xa9a9a9, darkgrey: 0xa9a9a9, darkgreen: 0x006400, darkkhaki: 0xbdb76b,
      darkmagenta: 0x8b008b, darkolivegreen: 0x556b2f, darkorange: 0xff8c00, darkorchid: 0x9932cc,
      darkred: 0x8b0000, darksalmon: 0xe9967a, darkseagreen: 0x8fbc8f, darkslateblue: 0x483d8b,
      darkslategray: 0x2f4f4f, darkslategrey: 0x2f4f4f, darkturquoise: 0x00ced1,
      darkviolet: 0x9400d3, deeppink: 0xff1493, deepskyblue: 0x00bfff, dimgray: 0x696969,
      dimgrey: 0x696969, dodgerblue: 0x1e90ff, firebrick: 0xb22222, floralwhite: 0xfffaf0,
      forestgreen: 0x228b22, fuchsia: 0xff00ff, gainsboro: 0xdcdcdc, ghostwhite: 0xf8f8ff,
      gold: 0xffd700, goldenrod: 0xdaa520, gray: 0x808080, grey: 0x808080, green: 0x008000,
      greenyellow: 0xadff2f, honeydew: 0xf0fff0, hotpink: 0xff69b4, indianred: 0xcd5c5c,
      indigo: 0x4b0082, ivory: 0xfffff0, khaki: 0xf0e68c, lavender: 0xe6e6fa,
      lavenderblush: 0xfff0f5, lawngreen: 0x7cfc00, lemonchiffon: 0xfffacd, lightblue: 0xadd8e6,
      lightcoral: 0xf08080, lightcyan: 0xe0ffff, lightgoldenrodyellow: 0xfafad2,
      lightgray: 0xd3d3d3, lightgrey: 0xd3d3d3, lightgreen: 0x90ee90, lightpink: 0xffb6c1,
      lightsalmon: 0xffa07a, lightseagreen: 0x20b2aa, lightskyblue: 0x87cefa,
      lightslategray: 0x778899, lightslategrey: 0x778899, lightsteelblue: 0xb0c4de,
      lightyellow: 0xffffe0, lime: 0x00ff00, limegreen: 0x32cd32, linen: 0xfaf0e6,
      magenta: 0xff00ff, maroon: 0x800000, mediumaquamarine: 0x66cdaa, mediumblue: 0x0000cd,
      mediumorchid: 0xba55d3, mediumpurple: 0x9370db, mediumseagreen: 0x3cb371,
      mediumslateblue: 0x7b68ee, mediumspringgreen: 0x00fa9a, mediumturquoise: 0x48d1cc,
      mediumvioletred: 0xc71585, midnightblue: 0x191970, mintcream: 0xf5fffa, mistyrose: 0xffe4e1,
      moccasin: 0xffe4b5, navajowhite: 0xffdead, navy: 0x000080, oldlace: 0xfdf5e6, olive: 0x808000,
      olivedrab: 0x6b8e23, orange: 0xffa500, orangered: 0xff4500, orchid: 0xda70d6,
      palegoldenrod: 0xeee8aa, palegreen: 0x98fb98, paleturquoise: 0xafeeee,
      palevioletred: 0xdb7093, papayawhip: 0xffefd5, peachpuff: 0xffdab9, peru: 0xcd853f,
      pink: 0xffc0cb, plum: 0xdda0dd, powderblue: 0xb0e0e6, purple: 0x800080,
      rebeccapurple: 0x663399, red: 0xff0000, rosybrown: 0xbc8f8f, royalblue: 0x4169e1,
      saddlebrown: 0x8b4513, salmon: 0xfa8072, sandybrown: 0xf4a460, seagreen: 0x2e8b57,
      seashell: 0xfff5ee, sienna: 0xa0522d, silver: 0xc0c0c0, skyblue: 0x87ceeb,
      slateblue: 0x6a5acd, slategray: 0x708090, slategrey: 0x708090, snow: 0xfffafa,
      springgreen: 0x00ff7f, steelblue: 0x4682b4, tan: 0xd2b48c, teal: 0x008080, thistle: 0xd8bfd8,
      tomato: 0xff6347, turquoise: 0x40e0d0, violet: 0xee82ee, wheat: 0xf5deb3, white: 0xffffff,
      whitesmoke: 0xf5f5f5, yellow: 0xffff00, yellowgreen: 0x9acd32 };
    """
  }
}

extension JSBridgeValue.Font {
  static var initSrc: String {
    return """
    const ui.font.system = "systemfont";
    const ui.font.weight = { ultralight: -0.800000011920929, thin: -0.600000023841858,
      light: -0.400000005960464, regular: 0, medium: 0.230000004172325, semibold: 0.300000011920929,
      bold: 0.400000005960464, heavy: 0.560000002384186, black: 0.620000004768372 };
    """
  }
}

extension JSBridgeValue.Yoga {
  static var initSrc: String {
    return """
    /* direction */ const inherit = 0; const ltr = 1; const rtl = 2;
    /* align */ const auto = 0; const flexStart = 1; const center = 2; const flexEnd = 3;
    const stretch = 4; const baseline = 5; const spaceBetween = 6; const spaceAround= 7;
    /* display */ const flex = 0; const none = 1;
    /* flexDirection */ const column = 0; const columnReverse = 1; const row = 2;
    const rowReverse = 3;
    /* overflow */ const visible = 0; const hidden = 1; const absolute = 2;
    /* wrap */ const noWrap = 0; const wrap = 1; const wrapReverse = 2;
    """
  }
}

extension JSBridgeValue.UIKit {
  static var initSrc: String {
    return """
    ui.textAlignment = { left: 0, center: 1, right: 2, justified: 3, natural: 4 };
    ui.lineBreakMode = { byWordWrapping: 0, byCharWrapping: 1, byClipping: 2, byTruncatingHead: 3,
      byTruncatingTail: 4, byTruncatingMiddle: 5 };
    ui.imageOrientation = { up: 0, down: 1, left: 2, right: 3, upMirrored: 4, downMirrored: 5,
      leftMirrored: 6, rightMirrored: 6 }
    ui.imageResizingMode = { title: 0, stretch: 1 }
    ui.heightPreset = { none: 0, tiny: 20, xsmall: 28, small: 36, default: 44, normal: 49,
    medium: 52, large: 60, xlarge: 68, xxlarge: 104 }
    """
  }
}
