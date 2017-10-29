import Foundation
import JavaScriptCore

public class UIJsFragmentBuilder {
  public private(set) var context: JSContext!
  private var index = 0
  private var nodes: [Int: UIJsFragmentNode] = [:]
  private var rootNodes: [String: UIJsFragmentNode] = [:]

  struct Namespace {
    static let fragment = ("ui.fragment.", "ui_fragment_")
    static let style = ("ui.style.", "ui_style_")
  }

  private func runFunction<P: UIPropsProtocol & Codable>(function: String,
                                                         props: P?,
                                                         canvasSize: CGSize) -> JSValue? {
    assert(Thread.isMainThread)
    guard let context = context else {
      return nil
    }
    var propsDictionary: Any = NSDictionary()
    if let props = props {
      let jsonProps = try! JSONEncoder().encode(props)
      propsDictionary = try! JSONSerialization.jsonObject(with: jsonProps, options: [])
    }

    guard let jsfunction = context.objectForKeyedSubscript(function) else {
      print("'\(function)' not defined in js context.")
      return nil
    }

    return jsfunction.call(withArguments: [propsDictionary, canvasSize])
  }

  /// Build a fragment by running the javacript function named *function*.
  /// - parameter function: The js function that will generate a function.
  /// - parameter props: The props that will be encoded and passed to the js render function.
  /// - parameter canvasSize: The size of the canvas bounding rect.
  public func buildFragment<P: UIPropsProtocol & Codable>(function: String,
                                                          props: P? = nil,
                                                          canvasSize: CGSize) -> UINodeProtocol {

    let fun = "\(Namespace.fragment.1)\(function)"
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

  /// Resolve and apply a style computed by running the javacript function named *function*.
  /// - parameter view: The target view for this style.
  /// - parameter function: The js function that will generate a function.
  /// - parameter props: The props that will be encoded and passed to the js render function.
  /// - parameter canvasSize: The size of the canvas bounding rect.
  public func resolveStyle<P: UIPropsProtocol & Codable>(view: UIView,
                                                         function: String,
                                                         props: P? = nil,
                                                         canvasSize: CGSize) {
    let fun = "\(Namespace.style.1)\(function)"
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

  /// Load fragments source code.
  public func loadDefinition(source: String) {
    var pre = source.replacingOccurrences(of: Namespace.fragment.0, with: Namespace.fragment.1)
    pre = pre.replacingOccurrences(of: Namespace.style.0, with: Namespace.style.1)
    let _ = context?.evaluateScript("\(pre)")
  }

  /// Replaces the values that are *_JsBridge* compliant with their native bridge.
  private func bridgeDictionaryValues(_ dictionary: [String: Any]) -> [String: Any] {
    var result = dictionary
    for (key, value) in dictionary {
      if let value = value as? NSDictionary, let jsBrigeableValue = _JsBridge(dictionary: value) {
        result[key] = jsBrigeableValue.bridge()
      }
    }
    return result
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
      let bridgedDictionary = self.bridgeDictionaryValues(dictionary as! [String : Any])
      let node = UIJsFragmentNode(key: key, create: {
        YGBuild(type) ?? UIView()
      }) { config in
        YGSet(config.view, bridgedDictionary)
      }
      // Keep tracks of the children nodes.
      node.jsChildrenIndices = children.map { $0.intValue }
      node._debugType = type
      let index = self.index + 1
      self.index = index
      // Adds the created node to the pool of nodes.
      self.nodes[index] = node
      node.jsIndex = index
      return NSNumber(value: index)
    }
    let nodeBuildJSBridgeName: NSString = "Node"
    context?.setObject(nodeBuild, forKeyedSubscript: nodeBuildJSBridgeName)

    // Shortcuts for UIKit components name.
    for symbol in (YGUIKitSymbols() as! [NSString]) {
      context?.setObject(symbol, forKeyedSubscript: symbol)
    }

    context?.setObject(_JsBridge.Log.function, forKeyedSubscript: _JsBridge.Log.functionName)
    context?.setObject(_JsBridge.Color.function, forKeyedSubscript: _JsBridge.Color.functionName)
  }
}

/// *UINode* subclass that is being created from the javascript context.
public class UIJsFragmentNode: UINode<UIView> {
  var jsChildrenIndices: [Int] = []
  var jsIndex: Int = 0
}

// MARK: -

struct _JsBridge {
  struct Key {
    static let marker = "_jsbridge"
    static let type = "_type"
    static let value = "_value"
  }
  /// The underlying dictionary.
  var dictionary: NSDictionary
  var type: NSString { return dictionary[Key.type] as! NSString }
  var value: Any? { return dictionary[Key.value] }

  /// Failable init method.
  init?(dictionary: NSDictionary) {
    guard dictionary[Key.marker] != nil else { return nil }
    self.dictionary = dictionary
  }

  func bridge() -> AnyObject {
    switch type {
    case Color.type:
      return Color.bridge(value: self)
    default:
      print("unbridgeable js type.")
      return NSObject()
    }
  }

  /// *color(hex: Int, alpha: Int)* function in the javascript context.
  struct Color {
    static let type: NSString = "UIColor"
    static let functionName: NSString = "color"
    static let function: @convention(block) (Int, Int) -> NSDictionary = { rgb, alpha in
      let red = (rgb >> 16) & 0xff
      let green = (rgb >> 8) & 0xff
      let blue = rgb & 0xff

      var result = NSMutableDictionary()
      result[Key.marker] = true
      result[Key.type] = type
      result[Key.value] = [red, green, blue, alpha]
      return result
    }
    static func bridge(value: _JsBridge) -> UIColor {
      assert(value.type == Color.type)
      guard let components = value.value as? [Int], components.count == 4 else {
        print("malformed \(value.type) bridge value.")
        return .black
      }
      let rgba = components.map { CGFloat($0)/255.0 }
      return UIColor(red: rgba[0], green: rgba[1], blue: rgba[2], alpha: rgba[3])
    }
  }
  /// *log(message: String) function in the javascript context.
  struct Log {
    static let functionName: NSString = "log"
    static let function: @convention(block) (String) -> Void = { message in
      print("js: \(message)")
    }
  }
}
