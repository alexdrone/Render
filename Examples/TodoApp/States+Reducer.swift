import Foundation
import Dispatcher_iOS
import Render

protocol State: Dispatcher_iOS.StateType, Render.StateType { }

//MARK: - Dispatcher Extension

extension Dispatcher {

  var appStore: Store<AppState, Action> {
    return self.store(with: "appStore") as! Store<AppState, Action>
  }

  func initAppStore() {
    let store = Store<AppState, Action>(identifier: "appStore", reducer: TodoReducer())
    Dispatcher.default.register(store: store)
  }
}

//MARK: - States

final class AppState: State {
  /** The initial 'empty' value for this state. */
  var todoList: [TodoState] = []
}

final class TodoState: State {
  let id: String = NSUUID().uuidString.lowercased()
  var isNew: Bool = true
  var isDone: Bool = false
  var title: String = ""
  var date: Date = Date()
}

//MARK: - Actions

enum Action: ActionType {
  case add
  case name(id: String, title: String)
  case check(id: String)
  case clear
}

//MARK: - Reducer

class TodoReducer: Reducer<AppState, Action> {

  override func operation(for action: Action,
                          in store: Store<AppState, Action>) -> ActionOperation<AppState, Action> {

    switch action {
    case .add:
      return ActionOperation(action: action, store: store, block: self.add)

    case .name(_, _):
      return ActionOperation(action: action, store: store, block: self.name)

    case .clear:
      return ActionOperation(action: action, store: store, block: self.clear)

    case .check(_):
      return ActionOperation(action: action, store: store, block: self.check)
    }
  }

  private func add(operation: AsynchronousOperation,
                   action: Action,
                   store: Store<AppState, Action>) {
    defer { operation.finish() }
    guard store.state.todoList.filter({ $0.isNew }).isEmpty else { return  }
    store.updateState { $0.todoList.insert(TodoState(), at: 0) }
  }

  private func name(operation: AsynchronousOperation,
                    action: Action,
                    store: Store<AppState, Action>) {
    defer { operation.finish() }
    guard case .name(let id, let title) = action else { return }
    store.updateState {
      for todo in $0.todoList where todo.id == id {
        todo.isNew = false
        todo.title = title
        todo.date = Date()
      }
    }
  }

  private func clear(operation: AsynchronousOperation,
                     action: Action,
                     store: Store<AppState, Action>) {
    defer { operation.finish() }
    store.updateState { $0 = AppState() }
  }

  private func check(operation: AsynchronousOperation,
                     action: Action,
                     store: Store<AppState, Action>) {
    defer { operation.finish() }
    guard case .check(let id) = action else { return }
    store.updateState {
      let todo = $0.todoList.filter { $0.id == id }.first
      todo?.isDone = true
    }
  }

}
