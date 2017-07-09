import UIKit
import Foundation

public struct DebugNotification {
  public static let dumpViewHierarchyDescription = Notification.Name("io.render.debug.desc")
  public static let viewHierarchyDescriptionDidUpdate = Notification.Name("io.render.debug.update")
  public static let didPrintLogLine = Notification.Name("io.render.debug.log")
}

public final class Console: ConsoleType {

  public struct Description: CustomStringConvertible {
    public let id: String
    public let key: String
    public let type: String
    public let viewRef: String
    public let frame: String
    public let state: String
    public let props: String
    public internal(set) var children: [Console.Description] = []

    /// XML description of the node hierarchy.
    public var description: String {
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

  /// The shared debug instance.
  #if DEBUG && (arch(i386) || arch(x86_64)) && os(iOS)
  static let shared: ConsoleType = Console()
  #else
  static let shared: ConsoleType = NilConsole()
  #endif

  public private(set) var viewHierarchyDescriptions: [Description] = []
  public var viewHierarchyDescriptionString: String {
    var buffer = "<Application>"
    for desc in viewHierarchyDescriptions.reversed() {
      buffer += desc.description
    }
    buffer += "</Application>"
    return buffer
  }

  private var timer: Timer?
  private var isDirty: Bool = false
  #if DEBUG && (arch(i386) || arch(x86_64)) && os(iOS)
  private var server: HttpServer?
  #endif

  public func log(_ text: String) {
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
    startTimer()
    startServer()
  }

  public func startServer() {
    #if DEBUG && (arch(i386) || arch(x86_64)) && os(iOS)
    let server = HttpServer()
    server["/inspect"] = { [weak self] _ in
      HttpResponse.ok(.xml(self?.viewHierarchyDescriptionString ?? ""))
    }
    try? server.start()
    self.server = server
    #endif
  }

  public func add(description: Description) {
    assert(Thread.isMainThread)
    viewHierarchyDescriptions.append(description)
  }

  public func markDirty() {
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
    #if DEBUG && (arch(i386) || arch(x86_64)) && os(iOS)
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
    #if DEBUG && (arch(i386) || arch(x86_64)) && os(iOS)
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

/// Work as class cluster.
public protocol ConsoleType {
  func markDirty()
  func add(description: Console.Description)
  func log(_ text: String)
}

/// 'ConsoleType' implementation in production - no op.
public final class NilConsole: ConsoleType {
  public func markDirty() { }
  public func add(description: Console.Description) { }
  public func log(_ text: String) { }
}

/// Internal shorthand.
func log(_ text: String) {
  Console.shared.log(text)
}

extension NodeType {
  /// Returns a 'Console.Description' for this node.
  public func debugDescription() -> Console.Description {
    var address = "nil"
    if let view = renderedView {
      address = "\(Unmanaged<AnyObject>.passUnretained(view as AnyObject).toOpaque())"
    }
    func escapeDescription(_ string: String) -> String {
      var result = string
      result = result.replacingOccurrences(of: "<", with: "")
      result = result.replacingOccurrences(of: ">", with: "")
      result = result.replacingOccurrences(of: "\"", with: "'")
      result = result.replacingOccurrences(of: "Optional", with: "'")
      return result
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

