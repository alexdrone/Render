import Foundation
import Render

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
      layout.flexDirection = .row
      view.backgroundColor = Color.black
    }

    let card = Node<UIView>(identifier: "card") { (view, layout, size) in
      layout.alignSelf = .stretch
      layout.flexGrow = 1
      layout.margin = 8
      layout.flexDirection = .row
      view.backgroundColor = Color.white.withAlphaComponent(0.1)
    }

    // Title input field.
    let textField = Node<UITextField>(
      identifier: "input",
      create: { [weak self] in
        let field = UITextField()
        field.placeholder = "TODO"
        field.delegate = self
        field.textColor = Color.white
        field.font = Typography.mediumBold
        self?.textField = field
        return field
      },
      configure: { (view, layout, size) in
        layout.alignSelf = .stretch
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
                        value: state.isDone ? Color.white.withAlphaComponent(0.3) : Color.white,
                        range: NSMakeRange(0, attr.length))
      view.attributedText = attr
      view.font = Typography.mediumBold
      view.numberOfLines = 0
      layout.flexGrow = 1
      layout.margin = 16
      layout.alignSelf = .stretch
    }

    // The check button.
    let doneButton = Node<UIButton>(
      identifier: "doneButton",
      create: {
        let button = UIButton(type: UIButtonType.custom)
        button.setTitle("CHECK", for: .normal)
        button.titleLabel?.font = Typography.smallBold
        button.setTitleColor(Color.red, for: .normal)
        return button
      },
      configure: { (view, layout, size) in
        layout.justifyContent = .center
        layout.alignSelf = .stretch
        layout.width = 64
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
          title,
          doneButton,
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


