import UIKit
import Render
import Material

class ViewController: UITableViewController {

  let store: Store
  var state: AppState

  init(store: Store) {
    self.store = store
    self.state = self.store.state
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    self.store.register(observer: self)
    super.viewDidLoad()
    self.tableView.estimatedRowHeight = 100
    self.tableView.rowHeight = UITableViewAutomaticDimension
    self.tableView.separatorStyle = .none
    self.tableView.dataSource = self
    self.tableView.reloadData()
  }

}

//MARK: - UITableViewDelegate

extension ViewController {

  override func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
    return self.state.todoList.todos.count
  }

  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let id = CellPrototype.defaultIdentifier(TodoComponentView.self)
    let dequeued = tableView.dequeueReusableCell(withIdentifier: id)
    let cell = dequeued ?? ComponentTableViewCell<TodoComponentView>()

    guard let componentCell = cell as? ComponentTableViewCell<TodoComponentView> else {
      return cell
    }

    componentCell.mountComponentIfNecessary(TodoComponentView())
    componentCell.state = self.state.todoList.todos[indexPath.row]
    componentCell.componentView?.delegate = self
    componentCell.render()
    return cell
  }
  
}

//MARK: - Store Observer

extension ViewController: Observer {

  /** The store state changed. The components need to be re-rendered. */
  func onStateChange(_ state: AppState) {
    self.state = state
    self.tableView.reloadData()
  }

}

//MARK: - Component Delegate

extension ViewController: TodoComponentViewDelegate {

  /** The user finished adding a description for the todo item with the 'id' passed as argument. */
  func didNameTodo(id: String, title: String) {
    self.store.dispatch(action: .name(id: id, title: title))
  }

  /** The user tapped on the check button in the todo item with the 'id' passed as argument */
  func didCheckTodo(id: String) {
    self.store.dispatch(action: .check(id: id))
  }

}
