import Foundation
import UIKit
import Render

struct FooState: StateType {
  var numberOfDots = randomInt(1, max: 16)
  var text: String = randomString()
}

class FooComponentView: ComponentView<FooState> {

  override func construct(state: FooState?, size: CGSize = CGSize.undefined) -> NodeType {

    // Main wrapper.
    let wrapper = Node<UIView>() { (view, layout, size) in
      layout.width = size.width
      view.backgroundColor = Color.black
    }

    // Container view that simply changes the flex direction.
    let column = Node<UIView> { (_, layout, _) in
      layout.flexDirection = .row
    }

    let rightWrapper = Node<UIView>(){ (_, layout, _) in
      // Makes sure the right column covers all of the remaining space.
      layout.flexShrink = 1
      layout.flexGrow = 1
    }

    return wrapper.add(children: [
      column.add(children: [
        // A convenient way to reuse views is to simply create a function that returns a node.
        // In this way you could a very fine grained reusable fragments.
        Fragments.avatar(),
        rightWrapper.add(children: [
          // Fragments can take a function as argument. Remember view = function(state).
          Fragments.paddedLabel(text: state?.text),

          // You can nest complex components within components by using the 'ComponentNode' helper 
          // function.
          ComponentNode(type: DotComponentView.self) { component in
            component.numberOfDots = state?.numberOfDots ?? 0
          },
          Fragments.button()
        ])
      ])
    ])

  }
}
