import Foundation
import CoreRender
import Render

// MARK: - Coordinator

class DemoWidgetCoordinator: Coordinator {
  // Props.
  var propCountStartValue: UInt = 0
  // State.
  private(set) var count: UInt = 0
  private(set) var isRotated: Bool = false
  // Synthesized.
  var totalCount: UInt { propCountStartValue + count }

  func increase() {
    count += 1
    setNeedsReconcile()
  }

  override func onLayout() {
    // Override this to manually override the layout of some of the views in the view hierarchy.
    // e.g.
    // view(withKey: Const.increaseButtonKey)?.frame = ...
  }

  override func onTouchUp(inside sender: UIView) {
    self.increase()
  }
}

// MARK: - Body

func makeDemoWidget(context: Context, coordinator: DemoWidgetCoordinator) -> OpaqueNodeBuilder {
  VStackNode {
    LabelNode(text: "\(coordinator.totalCount)")
      .font(UIFont.systemFont(ofSize: 24, weight: .black))
      .textAlignment(.center)
      .textColor(.darkText)
      .background(.secondarySystemBackground)
      .width(Const.size + 8 * CGFloat(coordinator.totalCount))
      .height(Const.size)
      .margin(Const.margin)
      .cornerRadius(Const.cornerRadius)
    LabelNode(text: ">> TAP HERE TO SPIN THE BUTTON >>")
      .font(UIFont.systemFont(ofSize: 12, weight: .bold))
      .textAlignment(.center)
      .textColor(.systemRed)
      .height(Const.size)
      .margin(Const.margin)
    HStackNode {
      ButtonNode(reuseIdentifier: Const.increaseButtonKey, target: coordinator)
        .text("TAP HERE TO INCREASE THE COUNTER")
        .font(UIFont.systemFont(ofSize: 12, weight: .bold))
        .background(.systemIndigo)
        .padding(Const.margin * 2)
        .cornerRadius(Const.cornerRadius)
      EmptyNode()
    }
  }
  .alignItems(.center)
  .matchHostingViewWidth(withMargin: 0)
}

// MARK: - Constants

private struct Const {
  static let increaseButtonKey = "button_increase"
  static let size: CGFloat = 48.0
  static let cornerRadius: CGFloat = 8.0
  static let margin: CGFloat = 4.0
}
