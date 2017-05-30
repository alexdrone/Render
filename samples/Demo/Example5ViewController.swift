import Foundation
import UIKit
import Render

// from https://github.com/alexdrone/Render/issues/34

struct TableState: StateType {
  let number: Int = 100
}

class TableComponentView: ComponentView<TableState> {

  override func construct(state: TableState?, size: CGSize) -> NodeType {

    let list = TableNode() { (view, layout, size) in
      layout.width = size.width
      layout.height = size.height
      view.backgroundColor = Color.black
      view.separatorStyle = .none
    }

    let basicNodeFragments = [

      // Any node definition will be wrapped inside a UITableViewCell.
      Node<UIView>(identifier: "green") { (view, layout, size) in
        layout.width = size.width
        layout.height = 300
        view.backgroundColor = Color.green
      },

      Node<UIView>(identifier: "red") { (view, layout, size) in
        layout.width = size.width
        layout.height = 100
        view.backgroundColor = Color.red
      },

      // A node definition.
      Node<UIView>(identifier: "darkerGreen") { (view, layout, size) in
        layout.width = size.width
        layout.height = 300
        view.backgroundColor = Color.darkerGreen
      }
    ]

    let helloWorldFragments = (1..<(state?.number ?? 0)).map { index in
      ComponentNode(type: HelloWorldComponentView.self,
                    state: HelloWorldState(name:"\(index)"),
                    size: size)
    }

    list.add(children: basicNodeFragments + helloWorldFragments)
    return list
  }

}

class Example5ViewController: ViewController {

  private let component = TableComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(component)
    component.state = TableState()
    component.render(in: view.frame.size)
  }

  override func viewDidLayoutSubviews() {
    component.render(in: view.bounds.size)
    component.center = view.center
  }
}

