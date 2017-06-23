import Foundation
import UIKit
import Render

struct FooComponentViewState: StateType {
  var numberOfDots = randomInt(1, max: 16)
  var text: String = randomString()
}

class FooComponentView: ComponentView<FooComponentViewState> {

  required init() {
    super.init()
    self.state = FooComponentViewState()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("Not supported")
  }

  override func render() -> NodeType {
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
          Fragments.paddedLabel(text: self.state.text),

          // You can nest complex components within components by using the 'ComponentNode' helper 
          // function.
          ComponentNode(DotComponentView(), in: self) { (component, _) in
            component.numberOfDots = self.state.numberOfDots
          },
          Fragments.button()
        ])
      ])
    ])

  }
}
