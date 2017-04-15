import Foundation
import UIKit
import Render

struct NestedState: StateType {
  var numberOfItems = randomInt(1, max: 16)
}

class NestedComponentView: ComponentView<NestedState> {

  override func construct(state: NestedState?, size: CGSize = CGSize.undefined) -> NodeType {

    let n = state?.numberOfItems ?? 0

    func item() -> NodeType {
      // The small dots below the view.
      return Node<UIView> {
        (view, layout, size) in

        view.backgroundColor = Color.green
        view.layer.cornerRadius = 8
        layout.margin = 2
        layout.height = 16
        layout.width = 16
      }
    }

    return Node<UIView>(identifier: String(describing: NestedComponentView.self)) {
      (view, layout, size) in

      layout.margin = 4
      layout.flexDirection = .row
      layout.flexWrap = .wrap
    }.add(children: (0..<n).map { _ in item() })
  }

}
