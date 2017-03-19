import Foundation
import Render

class TodoState: StateType {
  let id: String = NSUUID().uuidString.lowercased()
  var isNew: Bool = true
  var isDone: Bool = false
  var title: String = ""
  var date: Date = Date()
}

class TodoListState: StateType {
  var todos: [TodoState] = [TodoState()]
}
