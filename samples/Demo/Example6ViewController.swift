import Foundation
import UIKit
import Render

class Example6ViewController: ViewController, ComponentController {
  var component = NumberListComponent()
  override func viewDidLoad() {
    super.viewDidLoad()
    componentControllerViewDidLoad()
  }
}

struct RandomCollectionState: StateType {
  var items: [String] = []
  init() {
    for idx in 0...10 {
      items.append("\(idx)")
    }
  }
  mutating func shuffleOne(from: Int) {
    let to = (from + 1) % items.count
    let tmp = items[from]
    items[from] = items[to]
    items[to] = tmp
  }
  mutating func removeOne(from: Int) {
    items = items.filter { $0 != items[from] }
  }
}

class WrappingComponent: StatelessComponent {
  override func render() -> NodeType {
    let containter = Node<UIView> { view, layout, size in
    }
    return containter.add(child: ComponentNode(NumberListComponent(), in: self, key: "list"))
  }
}

class NumberListComponent: ComponentView<RandomCollectionState> {
  required init() {
    super.init()
    self.state = RandomCollectionState()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func render() -> NodeType {
    let children = state.items.enumerated().map { (index, item) -> NodeType in
      return Node<UIView>(reuseIdentifier: "index", key: "\(item.hashValue)") {
        view, layout, size in
        layout.padding = 8
        layout.width = size.width
        view.backgroundColor = Color.red
        view.onTap { _ in
          self.setState { state in
            state.removeOne(from: index)
          }
        }
      }.add(child: Fragments.subtitleLabel(text: item))
    }
    let table = TableNode(key: "numberList", in: self) { view, layout, size in
      layout.width = size.width
      layout.height = size.height
      view.backgroundColor = Color.black
    }
    return table.add(children: children)
  }
}
