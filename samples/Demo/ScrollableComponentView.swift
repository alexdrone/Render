import UIKit
import Render

struct ScrollableDemoComponentViewState: StateType {
  let foos: [FooComponentViewState]
  init() {
    self.foos = (0..<randomInt(12, max: 48)).map { _ in FooComponentViewState() }
  }
}

class ScrollableDemoComponentView: ComponentView<ScrollableDemoComponentViewState> {

  required init() {
    super.init()
    self.state = ScrollableDemoComponentViewState()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("Not supported")
  }

  override func render() -> NodeType {
    return Node<UIScrollView>() { (view, layout, size) in
      (layout.width, layout.height)  = (size.width, size.height)
    }.add(children: state.foos.map { foo in
        // We create a component for every item in the state collection and we add it as a 
        // child for the main UIScrollView node.
      ComponentNode(FooComponentView(), in: self, state: foo)
    })
  }

}
