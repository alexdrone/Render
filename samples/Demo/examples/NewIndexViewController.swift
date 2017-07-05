import Foundation
import UIKit
import Render

class NewIndexViewController: ViewController, ComponentController, NewIndexComponentViewDelegate {

  typealias C =  NewIndexComponentView
  lazy var component = NewIndexComponentView()

  let titles: [(Int, String, String)] = [
    (0, "Stateless Components", "A simple stateless component with a static view hierarchy."),
    (1, "Stateful Component", "A counter that changes its internal state."),
    (2, "Dynamic View Hierarchy", "The view hierarchy changes at every render pass."),
    (3, "Nested Components", "ComponentViews can be used as nodes inside the render function."),
    (4, "ScrollView Container", "The simplest way to make a list of components."),
    (5, "TableNode and CollectionNode", "UITableView and UICollectionView wrappers with auto diff for row changes."),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    addComponentToViewControllerHierarchy()
  }

  override func viewDidLayoutSubviews() {
    renderComponent(options: [.preventViewHierarchyDiff])
  }

  func configureComponentProps() {
    component.titles = titles
    component.controller = self
  }

  func indexComponentDidSelectRow(index: Int) {
    switch index {
    case 0: self.navigationController?.pushViewController(StatelessComponentExampleViewController(), animated: true)
    case 1: self.navigationController?.pushViewController(CounterExampleViewController(), animated: true)
    case 2: self.navigationController?.pushViewController(DynamicViewHierarchyExampleViewController(), animated: true)
    case 3: self.navigationController?.pushViewController(NestedComponentsExampleViewController(), animated: true)
    case 4: self.navigationController?.pushViewController(ScrollExampleViewController(), animated: true)
    case 5: self.navigationController?.pushViewController(TableNodeExampleViewController(), animated: true)

    default: break
    }
  }
}

protocol NewIndexComponentViewDelegate: class {

  /// Delegates the selection of a specific cell back to the controller.
  func indexComponentDidSelectRow(index: Int)
}

class NewIndexComponentView: StatelessComponentView {

  weak var controller: NewIndexComponentViewDelegate?
  var titles: [(Int, String, String)] = []

  required init() {
    super.init()
    defaultOptions = [.preventViewHierarchyDiff]
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func render() -> NodeType {
    let children = titles.map { item in
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

