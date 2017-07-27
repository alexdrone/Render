import UIKit
import Foundation

struct DebugNotification {
  static let dumpViewHierarchyDescription = Notification.Name("io.render.debug.desc")
  static let viewHierarchyDescriptionDidUpdate = Notification.Name("io.render.debug.update")
  static let didPrintLogLine = Notification.Name("io.render.debug.log")
}

/// Internal console and debug server.
final class Console: ConsoleType {

  /// Represent the description of a given node at a given point of time.
  struct Description: CustomStringConvertible {
    /// The node reuse identifier.
    let id: String
    /// The node unique key.
    let key: String
    /// The class for the node rendered view.
    let type: String
    /// The pointer to the view instance associated to this node.
    let viewRef: String
    /// The frame of that view.
    let frame: String
    /// The serialized state.
    let state: String
    /// The serialized properties (through reflection).
    let props: String
    /// Children description nodes.
    internal(set) var children: [Console.Description] = []

    /// xml description of the node hierarchy.
    var description: String {
      var buffer = ""
      func desc(_ obj: Description, level: Int = 0) {
        buffer += "\n"
        for _ in 0...level { buffer += "\t"  }
        buffer += "<\(obj.id)"
        if !obj.key.isEmpty { buffer += " key=\"\(obj.key)\"" }
        buffer += " frame=\"\(obj.frame)\" type=\"\(obj.type)\" ref=\"\(obj.viewRef)\""
        if !obj.state.isEmpty { buffer += " state=\"\(obj.state)\"" }
        if !obj.props.isEmpty { buffer += " props=\"\(obj.props)\"" }
        if !obj.children.isEmpty {
          buffer += ">"
          for child in obj.children { desc(child, level: level+1) }
          buffer += "\n"
          for _ in 0...level { buffer += "\t"  }
          buffer += "</\(obj.id)>"
        } else {
          buffer += "/>"
        }
      }
      desc(self)
      return buffer
    }
  }

  #if (arch(i386) || arch(x86_64)) && os(iOS)
  /// The console / debug server is instantiated only in the simulator for the time being.
  static let shared: ConsoleType = Console()
  #else
  /// Every call to the console is going to be a no-op on the device.
  static let shared: ConsoleType = NilConsole()
  #endif

  /// The current description trees.
  private(set) var viewHierarchyDescriptions: [Description] = []

  /// xml representation of all of the descriptions.
  var viewHierarchyDescriptionString: String {
    var buffer = "<Application>"
    for desc in viewHierarchyDescriptions.reversed() {
      buffer += desc.description
    }
    buffer += "</Application>"
    return buffer
  }

  private var timer: Timer?
  private var serverStarted: Bool = false
  private var isDirty: Bool = false
  #if (arch(i386) || arch(x86_64)) && os(iOS)
  private var server: HttpServer?
  #endif

  func log(_ text: String) {
    print(text)
    NotificationCenter.default.post(name: DebugNotification.didPrintLogLine, object: text)
  }

  private init() {
    let center = NotificationCenter.default
    center.addObserver(self,
                       selector: #selector(willEnterForeground),
                       name: NSNotification.Name.UIApplicationWillEnterForeground,
                       object: nil)
    center.addObserver(self,
                       selector: #selector(didEnterBackground),
                       name: NSNotification.Name.UIApplicationDidEnterBackground,
                       object: nil)
  }

  /// Starts the server on localhost:8080/inspect.
  func startServer() {
    #if (arch(i386) || arch(x86_64)) && os(iOS)
    serverStarted = true
    let server = HttpServer()
    server["/inspect"] = { [weak self] _ in
      HttpResponse.ok(.xml(self?.viewHierarchyDescriptionString ?? ""))
    }
    try? server.start()
    self.server = server
    startTimer()
    #endif
  }

  func add(description: Description) {
    assert(Thread.isMainThread)
    viewHierarchyDescriptions.append(description)
  }

  func markDirty() {
    assert(Thread.isMainThread)
    isDirty = true
  }

  private dynamic func willEnterForeground() {
    startTimer()
  }

  private dynamic func didEnterBackground() {
    stopTimer()
  }

  deinit {
    stopTimer()
  }

  /// Starts the polling timer.
  private func startTimer() {
    #if (arch(i386) || arch(x86_64)) && os(iOS)
    guard serverStarted else { return }
    timer = Timer.scheduledTimer(timeInterval: 2,
                                 target: self,
                                 selector: #selector(timerDidFire(timer:)),
                                 userInfo: nil,
                                 repeats: true)
    #endif
  }

  /// Stops the polling timer.
  private func stopTimer() {
    timer?.invalidate()
  }

  /// Check it the console is dirty and in that case asks components to dump their description.
  private dynamic func timerDidFire(timer: Timer) {
    #if (arch(i386) || arch(x86_64)) && os(iOS)
    assert(Thread.isMainThread)
    guard isDirty else {
      return
    }
    isDirty = false
    viewHierarchyDescriptions = []
    let center = NotificationCenter.default
    center.post(name: DebugNotification.dumpViewHierarchyDescription, object: nil)
    // Runs it in the next run loop.
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
      center.post(name: DebugNotification.viewHierarchyDescriptionDidUpdate, object: nil)
    }
    #endif
  }
}

/// Class cluster for the console.
protocol ConsoleType {
  func markDirty()
  func add(description: Console.Description)
  func log(_ text: String)
  func startServer()
}

/// 'ConsoleType' implementation in production - no op.
final class NilConsole: ConsoleType {
  func markDirty() { }
  func add(description: Console.Description) { }
  func log(_ text: String) { }
  func startServer() { }
}

/// Internal shorthand.
func log(_ text: String) {
  Console.shared.log(text)
}

extension NodeType {

  /// Returns a 'Console.Description' for this node.
  func debugDescription() -> Console.Description {
    var address = "nil"
    if let view = renderedView {
      address = "\(Unmanaged<AnyObject>.passUnretained(view as AnyObject).toOpaque())"
    }
    func escapeDescription(_ string: String) -> String {
      var result = string
      for c in ["<", ">", "\"",  "Optional"] {
        result = result.replacingOccurrences(of: c, with:  "'")
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
    return Console.Description(id: key.reuseIdentifier,
                               key: key.key,
                               type: debugType,
                               viewRef: address,
                               frame: "\(renderedView?.frame ?? CGRect.zero)",
                               state: state,
                               props :props,
                               children: children.map { $0.debugDescription() })
  }
}

/// Starts the debug server on localhost:8080/inspect.
/// - Note: The debug server is only available in the simulator.
public func startDebugServer() {
  Console.shared.startServer()
}


