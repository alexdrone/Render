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
    public let size: String
    public let state: String
    public internal(set) var children: [Console.Description] = []

    /// XML description of the node hierarchy.
    public var description: String {
      var buffer = ""
      func desc(_ obj: Description, level: Int = 0) {
        buffer += "\n"
        for _ in 0...level { buffer += "\t"  }
        buffer += "<\(obj.id)"
        if !obj.key.isEmpty { buffer += " key=\"\(obj.key)\"" }
        buffer += " size=\"\(obj.size)\" type=\"\(obj.type)\" ref=\"\(obj.viewRef)\""
        if !obj.state.isEmpty { buffer += " state=\"\(obj.state)\"" }
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
  #if DEBUG
  static let shared: ConsoleType = Console()
  #else
  static let shared: ConsoleType = NilConsole()
  #endif

  public private(set) var viewHierarchyDescriptions: [Description] = []
  private var timer: Timer?
  private var isDirty: Bool = false
  private var server: HttpServer?

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
    //startTimer()
    //startServer()
  }

  public func startServer() {
    let server = HttpServer()
    server["/inspect"] = { _ in
      HttpResponse.ok(.xml(self.viewHierarchyDescriptions.first?.description ?? ""))
    }
    try? server.start()
    self.server = server
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
    timer = Timer.scheduledTimer(timeInterval: 2,
                                 target: self,
                                 selector: #selector(timerDidFire(timer:)),
                                 userInfo: nil,
                                 repeats: true)
  }

  /// Stops the polling timer.
  private func stopTimer() {
    timer?.invalidate()
  }

  /// Check it the console is dirty and in that case asks components to dump their description.
  private dynamic func timerDidFire(timer: Timer) {
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
  }
}

/// Work as class cluster.
public protocol ConsoleType {
  func markDirty()
  func add(description: Console.Description)
  func log(_ text: String)
}

/// 'ConsoleType' implementation in production - no op.
public final class NilConsole {
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
    return Console.Description(id: key.reuseIdentifier,
                               key: key.key,
                               type: debugType,
                               viewRef: address,
                               size: "\(renderedView?.frame.size ?? CGSize.zero)",
                               state: associatedComponent?.anyState.description ?? "",
                               children: children.map { $0.debugDescription() })
  }
}

