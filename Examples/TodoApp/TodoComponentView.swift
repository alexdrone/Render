import Foundation
import Render
import Material

protocol TodoComponentViewDelegate: class {

  /** The user finished adding a description for the todo item with the 'id' passed as argument. */
  func didNameTodo(id: String, title: String)

  /** The user tapped on the check button in the todo item with the 'id' passed as argument */
  func didCheckTodo(id: String)
}

class TodoComponentView: ComponentView<TodoState>, UITextFieldDelegate {

  weak var delegate: TodoComponentViewDelegate?
  weak var textField: UITextField?

  override func construct(state: TodoState?, size: CGSize) -> NodeType {
    guard let state = state else {
      return Node<UIView>()
    }

    // Main wrapper element.
    let container = Node<UIView>(identifier: "container") { (view, layout, size) in
      layout.width = size.width
      view.backgroundColor = UIColor.white
    }

    // Card with depth.
    let card = Node<UIView>(identifier: "card") { (view, layout, size) in
      layout.alignSelf = .stretch
      layout.margin = 8
      layout.flexDirection = .row
      view.backgroundColor = Color.grey.lighten5
    }

    // Title input field.
    let textField = Node<TextField>(
      identifier: "input",
      create: { [weak self] in
        let field = TextField()
        field.placeholder = "TODO"
        field.delegate = self
        field.font = Material.Font.boldSystemFont(ofSize: 16)
        self?.textField = field
        return field
      },
      configure: { (view, layout, size) in
        layout.alignSelf = .stretch
        layout.flexGrow = 1
        layout.margin = 16
        layout.marginTop = 24
      })

    // Title label.
    let title = Node<UILabel>(identifier: "title") { (view, layout, size) in
      let attr = NSMutableAttributedString(string: state.title)
      attr.addAttribute(NSStrikethroughStyleAttributeName,
                        value: state.isDone ? 2 : 0,
                        range: NSMakeRange(0, attr.length))
      attr.addAttribute(NSForegroundColorAttributeName,
                        value: state.isDone ? Color.grey.darken4 : Color.lightBlue.darken3,
                        range: NSMakeRange(0, attr.length))
      view.attributedText = attr
      view.font = Material.Font.boldSystemFont(ofSize: 15)
      view.numberOfLines = 0
      layout.flexShrink = 1
      layout.margin = 16
    }

    // The check button.
    let doneButton = Node<IconButton>(
      identifier: "doneButton",
      create: {
        let button = IconButton(image: Icon.cm.check)
        return button
      },
      configure: { (view, layout, size) in
        layout.justifyContent = .center
        layout.alignSelf = .stretch
        layout.width = 42
        layout.marginLeft = 8
        view.isHidden = state.isDone
        view.addTarget(self, action: #selector(self.didTapCheckButton), for: .touchUpInside)
    })

    return container.add(child:
      card.add(children:
        state.isNew ? [
          // New todo.
          textField
        ] : [
          // Todo with a title already.
          doneButton,
          title
        ])
    )
  }

  override func didRender() {
    super.didRender()
    guard let state = state, state.isNew else {
      return
    }
    // After we render the component we want to make sure the texfield is new first responder.
    self.textField?.becomeFirstResponder()
  }

  /** The user tapped on the check button in the todo item. */
  private dynamic func didTapCheckButton() {
    guard let state = state, !state.isDone else {
      return
    }
    self.delegate?.didCheckTodo(id: state.id)
  }

  //MARK: - UITextFieldDelegate

  dynamic func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let state = self.state else {
      return true
    }
    self.delegate?.didNameTodo(id: state.id, title: textField.text ?? "")
    return true
  }

  dynamic func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    return true
  }
}
