import Foundation
import Render

//MARK: - States

class AppState: StateType {
  var todoList = TodoListState()
}

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

//MARK: - Actions

enum Action {
  case add
  case name(id: String, title: String)
  case check(id: String)
  case clear
}

//MARK: - Reducer

protocol Observer: class {
  func onStateChange(_ state: AppState)
}

final class Store {

  var state = AppState()
  var observers: [Observer] = []

  func register(observer: Observer) {
    self.observers.append(observer)
  }

  func deregister(observer: Observer) {
    self.observers = self.observers.filter { $0 === observer }
  }

  func dispatch(action: Action) {
    switch action {

    case .add:
      let new = self.state.todoList.todos.filter { $0.isNew }
      guard new.isEmpty else {
        return
      }
      self.state.todoList.todos.insert(TodoState(), at: 0)

    case .name(let id, let title):
      for todo in self.state.todoList.todos where todo.id == id {
        todo.isNew = false
        todo.title = title
        todo.date = Date()
      }

    case .check(let id):
      let todo = self.state.todoList.todos.filter { $0.id == id }.first
      todo?.isDone = true

    case .clear:
      self.state.todoList = TodoListState()

    }

    for observer in self.observers {
      observer.onStateChange(self.state)
    }
  }
}
