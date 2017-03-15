import UIKit
import Render

struct FooCollectionState: StateType {
  let foos: [FooState]

  init() {
    self.foos = (0..<randomInt(12, max: 128)).map { _ in FooState() }
  }
}

class ScrollableDemoComponentView: ComponentView<FooCollectionState> {

  var nestedComponents: [FooComponentView] = []

  override func construct(state: FooCollectionState?, size: CGSize = CGSize.undefined) -> NodeType {
    guard let state = state else {
      return NilNode()
    }
    return Node<UIScrollView>(identifier: String(describing: ScrollableDemoComponentView.self)) {
      (view, layout, size) in

      layout.width = size.width
      layout.height = size.height
      }.add(children:  state.foos.map { foo in
        // We create a component for every item in the state collection and we add it as a 
        // child for the main UIScrollView node.
        FooComponentView().construct(state: foo)
      })
  }

}
