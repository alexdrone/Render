import Foundation
import Render

class TodoListComponentView: ComponentView<TodoListState> {

  weak var delegate: TodoComponentViewDelegate?

  override func construct(state: TodoListState?, size: CGSize) -> NodeType {
    let todos = state?.todoList ?? []

    let children = todos.map { state in
      return ComponentNode(type: TodoComponentView.self, state: state, size: size) {
        $0.state = state
        $0.delegate = self.delegate
      }
    }
    return TableNode() { (view, layout, size) in
      view.backgroundColor = Color.black
      view.contentInset = UIEdgeInsetsMake(64, 0, 0, 0)
      layout.width = size.width
      layout.height = size.height
    }.add(children: children)
  }
  
}
