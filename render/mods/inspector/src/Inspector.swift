import UIKit

extension UIComponent {
  /// ⌘ + R to reload the component.
  func hookHotReload() {
    #if targetEnvironment(simulator)
      KeyCommands.register(input: "r", modifierFlags: .command) { [weak self] in
        print("⌘ + R Reloading...")
        self?.forceComponentReload()
      }
    #endif
  }
}

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
      guard let `self` = self, self.parent == nil else {
        return
      }
      let addressPrefix = self.isEmbeddedInCell ? (self.key ?? "n/a") : ""
      if let description = self.root.inspectorDescription(addressPrefix: addressPrefix),
        !(self.root is UINilNode)  {
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
  func inspectorDescription(addressPrefix: String = "") -> [String: Any]? {
    var address = "nil"
    if let view = renderedView {
      address = "\(Unmanaged<AnyObject>.passUnretained(view as AnyObject).toOpaque())"
    }
    func escape(_ string: String) -> String {
      var result = string
      for c in [("<", "&lt;"), (">", "&gt;"), ("&", "&amp;"), ("\"", "&quot;"), ("Optional","")] {
        result = result.replacingOccurrences(of: c.0, with:  c.1)
      }
      return result
    }
    func escapeReuseIdentifier(_ string: String) -> String {
      var result = string
      for c in ["<", ">", ",", ".", " ", "_"] {
        result = result.replacingOccurrences(of: c, with: "")
      }
      return result
    }
    let childrenDescription = (children + unmanagedChildren).filter {
      !($0 is UINilNode) }.map {
        $0.inspectorDescription(addressPrefix: addressPrefix)
    }
    return [
      "id": escapeReuseIdentifier(reuseIdentifier),
      "key": key ?? "",
      "type": _debugType,
      "viewRef": !addressPrefix.isEmpty ? "\(addressPrefix)_\(address)" : address,
      "frame": "\(renderedView?.frame ?? CGRect.zero)",
      "state": escape(_debugStateDescription),
      "props": escape(_debugPropDescription),
      "children": childrenDescription]
  }
}

// MARK: - KeyCommands
// forked from: Augustyniak/KeyCommands by Rafal Augustyniak

#if targetEnvironment(simulator)
  public typealias KeyModifierFlags  = UIKeyModifierFlags

  struct KeyActionableCommand {
    fileprivate let keyCommand: UIKeyCommand
    fileprivate let actionBlock: () -> ()

    func matches(_ input: String, modifierFlags: UIKeyModifierFlags) -> Bool {
      return keyCommand.input == input && keyCommand.modifierFlags == modifierFlags
    }
  }

  func == (lhs: KeyActionableCommand, rhs: KeyActionableCommand) -> Bool {
    return lhs.keyCommand.input == rhs.keyCommand.input
      && lhs.keyCommand.modifierFlags == rhs.keyCommand.modifierFlags
  }

  public enum KeyCommands {
    private static var __once: () = {
      exchangeImplementations(
        class: UIApplication.self,
        originalSelector: #selector(getter: UIResponder.keyCommands),
        swizzledSelector: #selector(UIApplication.KYC_keyCommands));
    }()
    fileprivate struct Static {
      static var token: Int = 0
    }

    struct KeyCommandsRegister {
      static var sharedInstance = KeyCommandsRegister()
      fileprivate var actionableKeyCommands = [KeyActionableCommand]()
    }

    public static func register(input: String,
                                modifierFlags: KeyModifierFlags,
                                action: @escaping () -> ()) {
      _ = KeyCommands.__once
      let keyCommand = UIKeyCommand(
        input: input,
        modifierFlags: modifierFlags,
        action: #selector(UIApplication.KYC_handleKeyCommand(_:)),
        discoverabilityTitle: "")
      let actionableKeyCommand = KeyActionableCommand(keyCommand: keyCommand, actionBlock: action)
      let index = KeyCommandsRegister.sharedInstance.actionableKeyCommands.index(
        where: { return $0 == actionableKeyCommand })
      if let index = index {
        KeyCommandsRegister.sharedInstance.actionableKeyCommands.remove(at: index)
      }
      KeyCommandsRegister.sharedInstance.actionableKeyCommands.append(actionableKeyCommand)
    }

    public static func unregister(input: String, modifierFlags: KeyModifierFlags) {
      let index = KeyCommandsRegister.sharedInstance.actionableKeyCommands.index(
        where: { return $0.matches(input, modifierFlags: modifierFlags) })
      if let index = index {
        KeyCommandsRegister.sharedInstance.actionableKeyCommands.remove(at: index)
      }
    }
  }

  extension UIApplication {
    @objc dynamic func KYC_keyCommands() -> [UIKeyCommand] {
      return KeyCommands.KeyCommandsRegister.sharedInstance.actionableKeyCommands.map({
        return $0.keyCommand
      })
    }

    @objc func KYC_handleKeyCommand(_ keyCommand: UIKeyCommand) {
      for command in KeyCommands.KeyCommandsRegister.sharedInstance.actionableKeyCommands {
        if command.matches(keyCommand.input!, modifierFlags: keyCommand.modifierFlags) {
          command.actionBlock()
        }
      }
    }
  }

  func exchangeImplementations(
    class classs: AnyClass,
    originalSelector: Selector,
    swizzledSelector: Selector
  ) -> Void {
    let originalMethod = class_getInstanceMethod(classs, originalSelector)
    let originalMethodImplementation = method_getImplementation(originalMethod!)
    let originalMethodTypeEncoding = method_getTypeEncoding(originalMethod!)
    let swizzledMethod = class_getInstanceMethod(classs, swizzledSelector)
    let swizzledMethodImplementation = method_getImplementation(swizzledMethod!)
    let swizzledMethodTypeEncoding = method_getTypeEncoding(swizzledMethod!)
    let didAddMethod = class_addMethod(
      classs,
      originalSelector,
      swizzledMethodImplementation,
      swizzledMethodTypeEncoding)
    if didAddMethod {
      class_replaceMethod(
        classs,
        swizzledSelector,
        originalMethodImplementation,
        originalMethodTypeEncoding)
    } else {
      method_exchangeImplementations(originalMethod!, swizzledMethod!)
    }
  }

#else
  public typealias KeyModifierFlags = Int

  public enum KeyCommands {
    public static func register(
      input: String,
      modifierFlags: KeyModifierFlags,
      action: () -> ()) {}
    public static func unregister(input: String, modifierFlags: KeyModifierFlags) {}
  }
#endif

