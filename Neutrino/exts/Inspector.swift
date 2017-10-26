import UIKit

extension UIComponent {
  /// Handle the inspector requests.
  func hookInspectorIfAvailable() {
    let injectionRequest = Notification.Name("INJECTION_BUNDLE_NOTIFICATION")
    let inspectorRequest = Notification.Name("RENDER_INSPECTOR_REQUEST")
    let inspectorResponse =  Notification.Name("RENDER_INSPECTOR_RESPONSE")
    let center = NotificationCenter.default
    center.addObserver(forName: injectionRequest, object: nil, queue: nil) { [weak self] _ in
      self?.setNeedsRender()
    }
    center.addObserver(forName: inspectorRequest, object: nil, queue: nil) { [weak self] _ in
      guard let `self` = self, self.parent == nil, !self.isEmbeddedInCell else {
        return
      }
      if let description = self.root.inspectorDescription() {
        NotificationCenter.default.post(name: inspectorResponse, object: description)
      }
    }
  }

  // Mark this component as dirty for the inspector cache.
  func inspectorMarkDirty() {
    let inspectorMarkDirty = Notification.Name("RENDER_INSPECTOR_MARK_DIRTY")
    NotificationCenter.default.post(name: inspectorMarkDirty, object: self)
  }
}


extension UINodeProtocol {
  /// Builds a XML description of the node.
  func inspectorDescription() -> [String: Any]? {
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
    let childrenDescription = (children + unmanagedChildren).filter { !($0 is UINilNode) }.map {
      $0.inspectorDescription()
    }
    return [
      "id": reuseIdentifier,
      "key": key ?? "",
      "type": _debugType,
      "viewRef": address,
      "frame": "\(renderedView?.frame ?? CGRect.zero)",
      "state": _debugStateDescription,
      "props": _debugPropsDescription,
      "children": childrenDescription]
  }
}

public let UINodeInspectorDefaultDelimiters: String = "__"

