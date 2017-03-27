import Foundation
import Dispatcher_iOS
import Render

protocol State: Dispatcher_iOS.StateType, Render.StateType { }

//MARK: - States

struct AppState: State {
  let todoList: [TodoState]

  init() {
    /** The initial 'empty' value for this state. */
    self.todoList = []
  }

  init(list: [TodoState]) {
    self.todoList = list
  }
}

struct TodoState: State {
  let id: String
  let isNew: Bool
  let isDone: Bool
  let title: String
  let date: Date

  init() {
    let id = NSUUID().uuidString.lowercased()
    self.init(id: id, isNew: true, isDone: false, title: "", date: Date())
  }

  init(id: String, isNew: Bool, isDone: Bool, title: String, date: Date) {
    self.id = id
    self.isNew = isNew
    self.isDone = isDone
    self.title = title
    self.date = date
  }

  func with(title: String) -> TodoState {
    return TodoState(id: self.id, isNew: false, isDone: self.isDone, title: title, date: self.date)
  }

  func markDone() -> TodoState {
    return TodoState(id: self.id, isNew: false, isDone: true, title: self.title, date: self.date)
  }

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

    store.updateState {  appState in

      // Make a copy of the todolist and add a new item on top of it.
      var list = appState.todoList
      list.insert(TodoState(), at: 0)

      // Create a new appstate with the new list.
      appState = AppState(list: list)
    }
  }

  private func name(operation: AsynchronousOperation,
                    action: Action,
                    store: Store<AppState, Action>) {
    defer { operation.finish() }
    guard case .name(let id, let title) = action else { return }

    store.updateState { appState in

      // Get the index of the todo item with the given id
      guard let index = appState.todoList.index(where: { $0.id == id }) else { return }

      // Make a copy of the todolist and set the title for the item at the index just found.
      var list = appState.todoList
      list[index] = appState.todoList[index].with(title: title)

      // Create a new appstate with the new list.
      appState = AppState(list: list)
    }
  }

  private func clear(operation: AsynchronousOperation,
                     action: Action,
                     store: Store<AppState, Action>) {
    defer { operation.finish() }

    store.updateState { appState in
      appState = AppState()
    }
  }

  private func check(operation: AsynchronousOperation,
                     action: Action,
                     store: Store<AppState, Action>) {
    defer { operation.finish() }
    guard case .check(let id) = action else { return }

    store.updateState { appState in

      // Get the index of the todo item with the given id
      guard let index = appState.todoList.index(where: { $0.id == id }) else { return }

      // Make a copy of the todolist and mark the item at the index just found as 'done'.
      var list = appState.todoList
      list[index] = appState.todoList[index].markDone()

      // Create a new appstate with the new list.
      appState = AppState(list: list)
    }
  }
}

//MARK: - Dispatcher Extension

extension Dispatcher {

  /** Convenience getter for the appstore. */
  var appStore: Store<AppState, Action> {
    return self.store(with: "appStore") as! Store<AppState, Action>
  }

  /** Creates the AppStore and register it to this 'dispatcher'. */
  func initAppStore() {
    let store = Store<AppState, Action>(identifier: "appStore", reducer: TodoReducer())
    Dispatcher.default.register(store: store)
  }
}

