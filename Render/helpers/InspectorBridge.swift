import UIKit

// MARK: - InspectorHooks

extension ComponentView {
  // Listen to the inspector requests.
  func hookInspectorIfAvailable() {
    let notification = Notification.Name("INJECTION_BUNDLE_NOTIFICATION")
    NotificationCenter.default.addObserver(forName: notification,
                                           object: nil,
                                           queue: nil) { [weak self] _ in
                                            self?.update()
    }
    let inspectorRequest = Notification.Name("RENDER_INSPECTOR_REQUEST")
    let inspectorResponse =  Notification.Name("RENDER_INSPECTOR_RESPONSE")
    NotificationCenter.default.addObserver(forName: inspectorRequest,
                                           object: nil,
                                           queue: nil) { [weak self] _ in
      guard let `self` = self, self.rootComponent == nil, self.associatedCell == nil else {
        return
      }
      let description = self.root.inspectorDescription()
      NotificationCenter.default.post(name: inspectorResponse, object: description)
    }
  }

  // Mark this object as dirty for the inspector cache.
  func inspectorMarkDirty() {
    let inspectorMarkDirty = Notification.Name("RENDER_INSPECTOR_MARK_DIRTY")
    NotificationCenter.default.post(name: inspectorMarkDirty, object: self)
  }
}

// MARK: - ReflectedStringConvertible

public protocol ReflectedStringConvertible : CustomStringConvertible {}
extension ReflectedStringConvertible {
  /// Returns a representation of the state in the form:
  /// Type(prop1: 'value', prop2: 'value'..)
  func reflectionDescription(delimiters: String = "") -> String {
    let mirror = Mirror(reflecting: self)
    var str = "{"
    var first = true
    for (label, value) in mirror.children {
      if let label = label {
        if first { first = false } else {  str += ", "  }
        str += "\(delimiters)\(label)\(delimiters): \(delimiters)\(value)\(delimiters)"
      }
    }
    str += "}"
    return str
  }

  public var description: String {
    return reflectionDescription()
  }
}

// MARK: - InspectorDescription

extension NodeType {
  /// Returns a description for the inspector.
  func inspectorDescription() -> [String: Any] {
    var address = "nil"
    if let view = renderedView {
      address = "\(Unmanaged<AnyObject>.passUnretained(view as AnyObject).toOpaque())"
    }
    func escapeDescription(_ string: String) -> String {
      var result = string
      for c in ["<", ">", "\"",  "Optional"] {
        result = result.replacingOccurrences(of: c, with:  "")
      }
      return result
    }
    var children: [NodeType] = self.children
    if let listNode = self as? ListNodeType {
      children = listNode.internalChildren
    }
    let delimiters = "__"
    let state = escapeDescription(
      associatedComponent?.anyState.reflectionDescription(delimiters: delimiters) ?? "")
    let props = escapeDescription (
      associatedComponent?.reflectionDescription(delimiters: delimiters) ?? "")
    return ["id": key.reuseIdentifier,
            "key": key.key,
            "type": debugType,
            "viewRef": address,
            "frame": "\(renderedView?.frame ?? CGRect.zero)",
            "state": state,
            "props": props,
            "children": children.map { $0.inspectorDescription() }]
  }
}
