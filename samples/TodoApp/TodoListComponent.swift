import Foundation
import Render

class TodoListComponentView: ComponentView<TodoListState> {

  weak var delegate: TodoComponentViewDelegate?

  override func construct(state: TodoListState, size: CGSize) -> NodeType {
    
    let todos = state.todoList

    // For every TodoState we create a TodoComponentView wrapped in a node.
    let children: [NodeType] = todos.map { state in
      return ComponentNode<TodoState>(TodoComponentView(), in: self, state: state, size: size) {
        $0.delegate = self.delegate
      }
    }
    return TableNode(identifier: "list") { (view, layout, size) in
      view.backgroundColor = Color.black
      view.contentInset.top = 64
      view.separatorStyle = .none
      layout.width = size.width
      layout.height = size.height
    }.add(children: children)
  }
  
}
