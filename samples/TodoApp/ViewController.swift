import UIKit
import Render
import Dispatcher_iOS

class ViewController: UIViewController {

  let dispatcher: Dispatcher

  private let todoListComponent = TodoListComponentView()

  init(dispatcher: Dispatcher = Dispatcher.default) {
    self.dispatcher = dispatcher
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {

    self.dispatcher.todoListStore.register(observer: self) { state, action in
      self.todoListComponent.state = state
      self.todoListComponent.delegate = self
      self.todoListComponent.render(in: self.view.bounds.size)
      self.view.setNeedsLayout()
    }

    super.viewDidLoad()
    self.configureNavigationBar()
    self.view.addSubview(self.todoListComponent)
  }

  override func viewDidLayoutSubviews() {
    self.todoListComponent.frame.origin = self.view.frame.origin
  }

  dynamic private func didTapAddButton() {
    self.dispatcher.dispatch(action: Action.add)
  }

  dynamic private func didTapCancelButton() {
    self.dispatcher.dispatch(action: Action.clear)
  }

  private func configureNavigationBar() {
    self.title = "TODOS"
    self.view.backgroundColor = Color.black
    self.navigationController?.navigationBar.titleTextAttributes =
        [NSForegroundColorAttributeName: Color.green]
    self.navigationController?.navigationBar.barTintColor = Color.black
    self.navigationController?.navigationBar.tintColor = Color.green
    self.navigationController?.navigationBar.shadowImage = UIImage()
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                             target: self,
                                                             action: #selector(didTapAddButton))
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash,
                                                            target: self,
                                                            action: #selector(didTapCancelButton))
    
  }
}


//MARK: - Component Delegate

extension ViewController: TodoComponentViewDelegate {

  /** The user finished adding a description for the todo item with the 'id' passed as argument. */
  func didNameTodo(id: String, title: String) {
    self.dispatcher.dispatch(action: Action.name(id: id, title: title))
  }

  /** The user tapped on the check button in the todo item with the 'id' passed as argument */
  func didCheckTodo(id: String) {
    self.dispatcher.dispatch(action: Action.check(id: id))
  }

}


