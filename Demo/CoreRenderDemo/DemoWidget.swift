import Foundation
import CoreRender
import CoreRenderObjC

// MARK: - Coordinator

class DemoWidgetCoordinator: Coordinator {
  var count: UInt = 0
  var isRotated: Bool = false

  @objc dynamic func increase() {
    count += 1
    setNeedsReconcile()
  }

  override func onLayout() {
    // Override this to manually override the layout of some of the views in the view hierarchy.
    // e.g.
    // view(withKey: Const.increaseButtonKey)?.frame = ...
  }
}

// MARK: - Body

func makeDemoWidget(context: Context, coordinator: DemoWidgetCoordinator) -> OpaqueNodeBuilder {
  VStackNode {
    LabelNode(text: "\(coordinator.count)")
      .font(UIFont.systemFont(ofSize: 24, weight: .black))
      .textAlignment(.center)
      .textColor(.darkText)
      .background(.secondarySystemBackground)
      .width(Const.size + 8 * CGFloat(coordinator.count))
      .height(Const.size)
      .margin(Const.margin)
      .cornerRadius(Const.cornerRadius)
    LabelNode(text: ">> TAP HERE TO SPIN THE BUTTON >>")
      .font(UIFont.systemFont(ofSize: 12, weight: .bold))
      .textAlignment(.center)
      .textColor(.systemOrange)
      .height(Const.size)
      .margin(Const.margin)
      .userInteractionEnabled(true)
      .onTouchUpInside { _ in
        coordinator.doSomeFunkyStuff()
    }
    HStackNode {
      ButtonNode(key: Const.increaseButtonKey)
        .text("TAP HERE TO INCREASE COUNT")
        .font(UIFont.systemFont(ofSize: 12, weight: .bold))
        .setTarget(
          coordinator, action: #selector(DemoWidgetCoordinator.increase), for: .touchUpInside)
        .background(.systemTeal)
        .padding(Const.margin * 2)
        .cornerRadius(Const.cornerRadius)
      EmptyNode()
    }
  }
  .alignItems(.center)
  .matchHostingViewWidth(withMargin: 0)
}

// MARK: - Manual View Manipulation Example

extension DemoWidgetCoordinator {
  // Example of manual access to the underlying view hierarchy.
  // Transitions can be performed in the node description as well, this is just an
  // example of manual view hierarchy manipulation.
  func doSomeFunkyStuff() {
    let transform = isRotated
      ? CGAffineTransform.identity
      : CGAffineTransform.init(rotationAngle: .pi)
    isRotated.toggle()
    UIView.animate(withDuration: 1) {
      self.view(withKey: Const.increaseButtonKey)?.transform = transform
    }
  }
}

// MARK: - Constants

struct Const {
  static let increaseButtonKey = "button_increase"
  static let size: CGFloat = 48.0
  static let cornerRadius: CGFloat = 8.0
  static let margin: CGFloat = 4.0
}
