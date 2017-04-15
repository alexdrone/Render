import Foundation
import Dispatcher_iOS
import Render

protocol State: Dispatcher_iOS.StateType, Render.StateType { }

//MARK: - States

struct TodoListState: State {
  let todoList: [TodoState]

  init() {
    self.todoList = []
  }

  init(list: [TodoState]) {
    self.todoList = list
  }

  func add(item: TodoState) -> TodoListState {
    var list = self.todoList
    list.insert(item, at: 0)
    return TodoListState(list: list)
  }

  func replace(id: String, closure: (TodoState) -> TodoState) -> TodoListState {
    guard let index = self.todoList.index(where: { $0.id == id }) else {
      return self
    }
    var list = self.todoList
    list[index] = closure(list[index])
    return TodoListState(list: list)
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

  func with(isNew: Bool? = nil, isDone: Bool? = nil, title: String? = nil, date: Date? = nil) -> TodoState {
    return TodoState(id: self.id,
                     isNew: isNew ?? self.isNew,
                     isDone: isDone ?? self.isDone,
                     title: title ?? self.title,
                     date: date ?? self.date)
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

class TodoReducer: Reducer<TodoListState, Action> {

  typealias O = ActionOperation<TodoListState, Action>
  typealias S = Store<TodoListState, Action>

  override func operation(for action: Action, in store: S) -> O {

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

  private func add(operation: AsynchronousOperation, action: Action, store: S) {
    defer {
      operation.finish()
    }
    guard store.state.todoList.filter({ $0.isNew }).isEmpty else {
      return
    }
    store.updateState {  state in
      state = state.add(item: TodoState())
    }
  }

  private func name(operation: AsynchronousOperation, action: Action, store: S) {
    defer {
      operation.finish()
    }
    guard case .name(let id, let title) = action else {
      return
    }
    store.updateState { state in
      state = state.replace(id: id) { $0.with(isNew: false, title: title) }
    }
  }

  private func clear(operation: AsynchronousOperation, action: Action, store: S) {
    defer {
      operation.finish()
    }
    store.updateState { state in
      state = TodoListState()
    }
  }

  private func check(operation: AsynchronousOperation, action: Action, store: S) {
    defer {
      operation.finish()
    }
    guard case .check(let id) = action else {
      return
    }
    store.updateState { state in
      state = state.replace(id: id) { $0.with(isDone: true) }
    }
  }
}

//MARK: - Dispatcher Extension

extension Dispatcher {

  static let todoListStoreIndetifier = "todoList"

  var todoListStore: Store<TodoListState, Action> {
    return self.store(with: Dispatcher.todoListStoreIndetifier) as! Store<TodoListState, Action>
  }

  func initTodoListStore() {
    let store = Store<TodoListState, Action>(identifier:  Dispatcher.todoListStoreIndetifier, reducer: TodoReducer())
    Dispatcher.default.register(store: store)
  }
}

