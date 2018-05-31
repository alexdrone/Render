import Foundation

public protocol Disposable: class {
  /// Whether this object has been disposed or not.
  /// Once an object is disposed it cannot be used any longer.
  var isDisposed: Bool { get set }
  /// Dispose the object and makes it unusable.
  func dispose()
}

public extension Disposable {
  /// Logs any access to a disposed object.
  public func disposedWarning() {
    if isDisposed {
      var ptr = self
      withUnsafePointer(to: &ptr) {
        print(String(format: "⤬ DISPOSED access to (%p) of type %@.",
                     arguments: [$0, String(describing:(type(of: self)))]))
      }
    }
  }
}

public struct DebugFlags {
  /// The allocation trace desired.
  public enum Allocation: Int {
    case context, component, vc
  }
  /// Logs to console the allocation of contextes and components.
  static var traceAllocations: [Allocation] = [.context]
  /// Turns on/off the hot reload in the simulator.
  static var isHotReloadInSimulatorEnabled: Bool = true

  /// Determines whether the allocation/deallocation of this object should be traced according to
  /// the current debug settings.
  public static func shouldTraceAllocation(for object: Any) -> Bool {
    if traceAllocations.contains(.component) && object is UIComponentProtocol {
      return true
    } else if traceAllocations.contains(.context) && (object is UIContextProtocol) {
      return true
    } else if traceAllocations.contains(.vc) && object is UIViewController {
      return true
    } else {
      return false
    }
  }
}

/// Trace the object allocation (only if *DebugFlags.traceAllocations* is enabled).
public func logAlloc(type: String, object: Any, details: String? = nil, time: CFAbsoluteTime = -1) {
  guard DebugFlags.shouldTraceAllocation(for: object) else { return }
  var ptr = object
  withUnsafePointer(to: &ptr) {
    var format = "* ALLOC \(type) (%p) init"
    if let details = details, !details.isEmpty { format += " \(details)" }
    format = time > 0 ? format + " in %2f ms." : format + "."
    print(String(format: format, arguments: [$0, time]))
  }
}

/// Trace the object deallocation (only if *DebugFlags.traceAllocations* is enabled).
public func logDealloc(type: String, object: Any, details: String? = nil) {
  guard DebugFlags.shouldTraceAllocation(for: object) else { return }
  var ptr = object
  withUnsafePointer(to: &ptr) {
    var format = "✝ DEALLOC \(type):%p deinit"
    if let details = details, !details.isEmpty { format += " \(details)" }
    format += "."
    print(String(format: format, arguments: [$0]))
  }
}

public func string<T>(fromType aType: T) -> String {
  return String(describing: aType)
}
