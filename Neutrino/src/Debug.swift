import Foundation

public struct DebugFlags {
  /// Logs to console the allocation of contextes and components.
  static let traceAllocations: Bool = true
}

public func logAlloc(type: String, object: Any, details: String? = nil, time: CFAbsoluteTime = -1) {
  guard DebugFlags.traceAllocations else { return }
  var ptr = object
  withUnsafePointer(to: &ptr) {
    var format = "* ALLOC \(type) (%p) init"
    if let details = details, !details.isEmpty { format += " \(details)" }
    format = time > 0 ? format + " in %2f ms." : format + "."
    print(String(format: format, arguments: [$0, time]))
  }
}

public func logDealloc(type: String, object: Any, details: String? = nil) {
  guard DebugFlags.traceAllocations else { return }
  var ptr = object
  withUnsafePointer(to: &ptr) {
    var format = "† DEALLOC \(type):%p deinit"
    if let details = details, !details.isEmpty { format += " \(details)" }
    format += "."
    print(String(format: format, arguments: [$0]))
  }
}
