import Foundation
import UIKit
import Render

// from https://github.com/alexdrone/Render/issues/34

struct TableComponentViewState: StateType {
  let number: Int = 100
}

class TableComponentView: ComponentView<TableComponentViewState> {

  required init() {
    super.init()
    self.state = TableComponentViewState()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("Not supported")
  }
  
  override func render() -> NodeType {

    let list = TableNode(key: "table", in: self) { (view, layout, size) in
      layout.width = size.width
      layout.height = size.height
      view.backgroundColor = Color.black
    }

    let width = referenceSize().width

    let basicNodeFragments = [

      // Any node definition will be wrapped inside a UITableViewCell.
      Node<UIView>(key: "green") { (view, layout, size) in
        layout.width = width/2
        layout.height = width/2
        view.backgroundColor = Color.green
      },

      Node<UIView>(key: "red") { (view, layout, size) in
        layout.width = width/2
        layout.height = width/2
        view.backgroundColor = Color.red
      },

      // A node definition.
      Node<UIView>(key: "darkerGreen") { (view, layout, size) in
        layout.width = width/2
        layout.height = width/2
        view.backgroundColor = Color.darkerGreen
      }
    ]

    let helloWorldFragments = (1..<state.number).map { index in
      ComponentNode(HelloWorldComponentView(), in: self, key: "\(index)")
    }

    list.add(children: basicNodeFragments + helloWorldFragments)
    return list
  }

}

class Example4ViewController: ViewController, ComponentController {

  var component = TableComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    addComponentToViewControllerHierarchy()
  }

  override func viewDidLayoutSubviews() {
    renderComponent(options: [.preventViewHierarchyDiff])
  }

  func configureComponentProps() {
    // No props to pass down to the component.
  }
}

