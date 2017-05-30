import Foundation
import Render

class TodoListComponentView: ComponentView<TodoListState> {

  weak var delegate: TodoComponentViewDelegate?

  override func construct(state: TodoListState?, size: CGSize) -> NodeType {
    self.prepareConstruct()
    
    let todos = state?.todoList ?? []

    // For every TodoState we create a TodoComponentView wrapped in a node.
    let children = todos.map { state in
      return ComponentNode(type: TodoComponentView.self, in: self, state: state, size: size) {
        $0.state = state
        $0.delegate = self.delegate
      }
    }
    return TableNode() { (view, layout, size) in
      view.backgroundColor = Color.black
      view.contentInset.top = 64
      layout.width = size.width
      layout.height = size.height
    }.add(children: children)
  }
  
}
