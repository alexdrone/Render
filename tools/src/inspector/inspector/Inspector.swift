import UIKit
import Foundation

struct DebugNotification {
  static let requestDescription = Notification.Name("RENDER_INSPECTOR_REQUEST")
  static let responseDescription = Notification.Name("RENDER_INSPECTOR_RESPONSE")
  static let markDirty = Notification.Name("RENDER_INSPECTOR_MARK_DIRTY")
}

/// Internal console and debug server.
final class Inspector: InspectorType {
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
    internal(set) var children: [Inspector.Description] = []
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
    // Construct a new description object from a dictionary.
    init?(dictionary: [String: Any]) {
      guard let id = dictionary["id"] as? String,
            let key = dictionary["key"] as? String,
            let type = dictionary["type"] as? String,
            let viewRef = dictionary["viewRef"] as? String,
            let frame = dictionary["frame"] as? String,
            let state = dictionary["state"] as? String,
            let props = dictionary["props"] as? String,
            let childrenDictionary = (dictionary["children"] as? [[String: Any]]) else {
        return nil
      }
      // Create children recursively.
      var children: [Description] = []
      for childDictionary in childrenDictionary {
        if let desc = Description(dictionary: childDictionary) {
          children.append(desc)
        }
      }
      // Assign properties.
      self.id = id
      self.key = key
      self.type = type
      self.viewRef = viewRef
      self.frame = frame
      self.state = state
      self.props = props
      self.children = children
    }
  }
  #if targetEnvironment(simulator)
  /// The console / debug server is instantiated only in the simulator for the time being.
  static let shared: InspectorType = Inspector()
  #else
  /// Every call to the console is going to be a no-op on the device.
  static let shared: InspectorType = NilInspector()
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
  #if targetEnvironment(simulator)
  private var server: HttpServer?
  #endif

  private init() {
    let center = NotificationCenter.default
    #if swift(>=4.2)
    let willEnterForegroundNotification = UIApplication.willEnterForegroundNotification
    let didEnterBackgroundNotification = UIApplication.didEnterBackgroundNotification
    #else
    let willEnterForegroundNotification = NSNotification.Name.UIApplicationWillEnterForeground
    let didEnterBackgroundNotification = NSNotification.Name.UIApplicationDidEnterBackground
    #endif
    center.addObserver(self,
                       selector: #selector(willEnterForeground),
                       name: willEnterForegroundNotification,
                       object: nil)
    center.addObserver(self,
                       selector: #selector(didEnterBackground),
                       name: didEnterBackgroundNotification,
                       object: nil)
    center.addObserver(self,
                       selector: #selector(markDirty),
                       name: DebugNotification.markDirty,
                       object: nil)
    center.addObserver(self,
                       selector: #selector(addDescription(notification:)),
                       name: DebugNotification.responseDescription,
                       object: nil)
  }

  deinit {
    stopTimer()
  }

  /// Starts the server on localhost:8080/inspect.
  public func startServer() {
    #if targetEnvironment(simulator)
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

  /// Adds the nodes description posted by a component view to the list of descriptions.
  @objc public dynamic func addDescription(notification: Notification) {
    assert(Thread.isMainThread)
    guard let object = notification.object as? [String: Any],
          let description = Description.init(dictionary: object) else { return }
    viewHierarchyDescriptions.append(description)
  }

  /// Marks the description cache as dirty.
  @objc public dynamic func markDirty() {
    assert(Thread.isMainThread)
    isDirty = true
  }

  /// Starts the polling timer when the application is in foreground.
  @objc private dynamic func willEnterForeground() {
    startTimer()
  }

  /// Stops the polling timer when the application is in background.
  @objc private dynamic func didEnterBackground() {
    stopTimer()
  }

  /// Starts the polling timer.
  private func startTimer() {
    #if targetEnvironment(simulator)
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
  @objc private dynamic func timerDidFire(timer: Timer) {
    #if targetEnvironment(simulator)
    assert(Thread.isMainThread)
    guard isDirty else {
      return
    }
    isDirty = false
    viewHierarchyDescriptions = []
    let center = NotificationCenter.default
    center.post(name: DebugNotification.requestDescription, object: nil)
    #endif
  }
}

/// Class cluster for the console.
public protocol InspectorType {
  func markDirty()
  func addDescription(notification: Notification)
  func startServer()
}

/// 'InspectorType' implementation in production - no op.
public final class NilInspector: InspectorType {
  @objc public dynamic func markDirty() { }
  @objc public dynamic func addDescription(notification: Notification) { }
  public func startServer() { }
}

/// Starts the debug server on localhost:8080/inspect.
/// - note: The debug server is only available in the simulator.
public func startRenderInspectorServer() {
  Inspector.shared.startServer()
}
