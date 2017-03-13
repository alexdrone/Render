//: Playground - noun: a place where people can play

import UIKit
import Render
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

struct AppState: StateType {
  var isOn = false
}

class MyView: ComponentView<AppState> {
  override func construct(state: AppState?, size: CGSize) -> NodeType {

    let children = state!.isOn ? []: [Node()]

    return Node().add(children: children)
  }
}

let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
container.backgroundColor = .white

let view = MyView()
view.state = AppState()
view.render(in: container.frame.size)

container.addSubview(view)

view

view.state?.isOn = true
view.render(in: container.frame.size)

view


PlaygroundPage.current.liveView = container
