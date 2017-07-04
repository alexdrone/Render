import Foundation
import UIKit
import Render

class IndexViewController: ViewController, ComponentController, IndexComponentViewDelegate {

  typealias C =  IndexComponentView
  lazy var component = IndexComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    component.controller = self
    componentControllerViewDidLoad()
  }

  struct State: StateType {
    let titles: [(Int, String, String)] = [
      (0, "Counter", "A simple component with static view hierarchy."),
      (1, "Nested components", "A component with a complex dynamic view hierarchy comprising of a nested component."),
      (2, "Scrolling components", "The contentsize for the wrapping scrollview component is automatically determined."),
      (3, "Table node", "Wraps the children nodes in UITableViewCells."),
      (4, "Layout %", "You can express size, margins and padding as %."),
      (5, "Table diffs", "Enable TableNode for fine grain diffs."),

    ]
  }

  func indexComponentDidSelectRow(index: Int) {
    switch index {
    case 0: self.navigationController?.pushViewController(Example1ViewController(), animated: true)
    case 1: self.navigationController?.pushViewController(Example2ViewController(), animated: true)
    case 2: self.navigationController?.pushViewController(Example3ViewController(), animated: true)
    case 3: self.navigationController?.pushViewController(Example4ViewController(), animated: true)
    case 4: self.navigationController?.pushViewController(Example5ViewController(), animated: true)
    case 5: self.navigationController?.pushViewController(Example6ViewController(), animated: true)
    default: break
    }
  }

  override func viewDidLayoutSubviews() {
    component.update(options: [])
  }
}

protocol IndexComponentViewDelegate: class {

  /// Delegates the selection of a specific cell back to the controller.
  func indexComponentDidSelectRow(index: Int)
}

class IndexComponentView: ComponentView<IndexViewController.State> {

  weak var controller: IndexComponentViewDelegate?

  required init() {
    super.init()
    defaultOptions = [.preventViewHierarchyDiff]
    state = IndexViewController.State()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func render() -> NodeType {
    let children = self.state.titles.map { item in
      indexCell(no: item.0, title: item.1, subtitle: item.2, onTap: { [weak self] _ in
        self?.controller?.indexComponentDidSelectRow(index: item.0)
      })
    }
    return TableNode(key: "indexList", in: self) { view, layout, size in 
      layout.width = size.width
      layout.height = size.height
      view.backgroundColor = Color.black
      view.separatorStyle = .none
    }.add(children: children)
  }

  func indexCell(no: Int, title: String, subtitle: String, onTap: @escaping () -> ()) -> NodeType {
    let container = Node<UIView>(reuseIdentifier: "index") { view, layout, size in
      view.onTap { _ in onTap() }
      view.backgroundColor = Color.black
      layout.padding = 8
      layout.width = size.width
      layout.flexDirection = .row
    }
    let textContainer = Node<UIView> { view, layout, size in
      view.backgroundColor = Color.black
      layout.flexDirection = .column
      layout.flex()
    }
    let numberLabel = Node<UILabel> { view, layout, size in
      layout.alignSelf = .stretch
      layout.margin = 4
      layout.width = 32
      view.backgroundColor = Color.red
      view.font = UIFont.boldSystemFont(ofSize: 16)
      view.textAlignment = .center
      view.textColor = Color.white
      view.text = "\(no+1)"
    }
    return container.add(children: [
      numberLabel,
      textContainer.add(children: [
        Fragments.paddedLabel(text: title),
        Fragments.subtitleLabel(text: subtitle)
      ])
    ])
  }
}
