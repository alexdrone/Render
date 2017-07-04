import Foundation
import UIKit
import Render

class NewIndexViewController: ViewController, ComponentController, IndexComponentViewDelegate {

  typealias C =  IndexComponentView
  lazy var component = IndexComponentView()

  let titles: [(Int, String, String)] = [
    (0, "Stateless Components", "A simple stateless component with a static view hierarchy."),

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
    default: break
    }
  }
}

protocol NewIndexComponentViewDelegate: class {

  /// Delegates the selection of a specific cell back to the controller.
  func indexComponentDidSelectRow(index: Int)
}

class NewIndexComponentView: StatelessComponent {

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

