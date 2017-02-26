import Foundation
import UIKit
import Render

struct FooState: StateType {
  var bar = NestedState()
  var numberOfLabels = randomInt(1, max: 4)
  var text: String = randomString()
}

class FooComponentView: ComponentView<FooState> {

  // Components can be composed.
  // See in the 'construct' method how this nested component is added to the hierarchy.
  let nestedComponent = NestedComponentView()

  override func construct(state: FooState?, size: CGSize = CGSize.undefined) -> NodeType {
    func content(state: FooState?, size: CGSize) -> NodeType {
      return Node<UIView>() { (view, layout, size) in
        layout.width = size.width
        view.backgroundColor = Color.black
      }
    }
    func columnWrapper() -> NodeType {
      // A wrapper that changes the direction of the elements from .colum (the default) to row.
      return Node<UIView> { (view, layout, size) in
        layout.flexDirection = .row
      }
    }
    func rightSideWrapper() -> NodeType {
      return Node<UIView>(){ (view, layout, size) in
        // Makes sure the right column covers all of the remaining space.
        layout.flexShrink = 1
        layout.flexGrow = 1
      }
    }
    return content(state: state, size: size).add(children: [
      columnWrapper().add(children: [
        Fragments.avatar(),
        rightSideWrapper().add(children: [
          Fragments.paddedLabel(text: state?.text),
          // The way we compose components is by manually calling 'construct' and pass the
          // component's state as argument.
          nestedComponent.construct(state: state?.bar),
          Fragments.button()
        ])
      ])
    ])
  }
}
