import UIKit
import RenderNeutrino

class ExampleTableComponent: UIComponent<UINilState, UINilProps> {

  override func render(context: UIContextProtocol) -> UINodeProtocol {

    let root = childComponent(UIDefaultTableComponent.self, key: childKey("table"))

    var nodes: [UINodeProtocol] = []
    for idx in 0...100 {
      let node = root.childComponent(Foo.Component.self, key: childKey("cell-\(idx)")).asNode()
      nodes.append(node)
    }
    root.props.sections.append(UITableComponentProps.Section(nodes: nodes))

    let rootNode = root.asNode()
    return rootNode
  }
}
