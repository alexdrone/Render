import PlaygroundSupport
import Render

//36: Emptying a node's children causes it to incorrectly measure its size.

PlaygroundPage.current.needsIndefiniteExecution = true

struct AppState: StateType {
    var isOn = false
}

class MyView: ComponentView<AppState> {
    override func construct(state: AppState?, size: CGSize) -> NodeType {
        let children = [
            Node<UILabel>() { label, layout, size in
                label.text = "text"
            },
            Node<UILabel>() { label, layout, size in
                label.text = "text"
            },
            Node<UILabel>() { label, layout, size in
                label.text = "text"
            }
        ]
        return Node<UIView>().add(children: [
            Node() { view, layout, size in
                view.backgroundColor = .gray
            }.add(children: state!.isOn ? []: children)
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
