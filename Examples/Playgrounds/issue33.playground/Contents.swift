import PlaygroundSupport
import Render

//33: Updating state after using NilNode makes the order of items reversed
// Fixed.

PlaygroundPage.current.needsIndefiniteExecution = true

struct AppState: StateType {
  var isOn = false
}

class MyView: ComponentView<AppState> {
  override func construct(state: AppState?, size: CGSize) -> NodeType {
    let bar = Node<UILabel>() { label, layout, size in
      label.text = "bar"
    }
    return Node<UIView>().add(children: [
        Node<UILabel>() { label, layout, size in
          label.text = "foo"
        },
        state!.isOn ? bar as NodeType : NilNode()
    ])
  }
}

let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
container.backgroundColor = .white

let view = MyView()
container.addSubview(view)

view.state = AppState()
view.render(in: container.frame.size)

container

view.state?.isOn = true
view.render(in: container.frame.size)

container

PlaygroundPage.current.liveView = container
