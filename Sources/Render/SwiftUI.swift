#if canImport(SwiftUI)
import UIKit
import SwiftUI
import CoreRender

extension Context {
  /// The context used for SwiftUI bridged views.
  public static let swiftUISharedContext = Context()
}

@available(iOS 13.0, *)
public struct CoreRenderBridgeView: UIViewRepresentable {
  /// The node hiearchy.
  public let buildBlock: (Context) -> OpaqueNodeBuilderConvertible

  public init(_ buildBlock: @escaping (Context) -> OpaqueNodeBuilderConvertible) {
    self.buildBlock = buildBlock
  }

  /// Creates a `UIView` instance to be presented.
  public func makeUIView(context: UIViewRepresentableContext<CoreRenderBridgeView>) -> HostingView {
    let hostingView = HostingView(context: CoreRender.Context.swiftUISharedContext, with: []) {
      context in self.buildBlock(context).builder()
    }
    return hostingView
  }

  /// Updates the presented `UIView` (and coordinator) to the latest configuration.
  public func updateUIView(
    _ uiView: HostingView,
    context: UIViewRepresentableContext<CoreRenderBridgeView>
  ) -> Void {
    uiView.setNeedsReconcile()
  }
}

#endif
