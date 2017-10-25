import UIKit
import RenderNeutrino

class ExampleTableComponent: UIComponent<UINilState, UINilProps> {

  override func render(context: UIContextProtocol) -> UINodeProtocol {

    let props = UITableComponentProps()
    let root = context.component(UITableComponent<UINilState, UITableComponentProps>.self,
                                 key: "table-example",
                                 props: props,
                                 parent: self)

    var nodes: [UINodeProtocol] = []
    for idx in 0...100 {
      let node = context.component(Foo.Component.self, key: "cell-\(idx)", props: Foo.Props(), parent: self).asNode()
      nodes.append(node)
    }
    let section = UITableComponentProps.Section(nodes: nodes)
    props.sections.append(section)

    let rootNode = root.asNode()
    return rootNode
  }
}
