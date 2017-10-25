import UIKit
import RenderNeutrino

class ExampleTableComponent: UIComponent<UINilState, UINilProps> {

  override func render(context: UIContextProtocol) -> UINodeProtocol {

    let table = childComponent(UIDefaultTableComponent.self, key: childKey("table"))
    table.props.configuration = { view, canvasSize in
      view.yoga.width = canvasSize.width
      view.yoga.height = canvasSize.height
      view.backgroundColor = Color.black
    }

    var nodes: [UIComponentProtocol] = []
    for idx in 0...4 {
      let node = table.cell(Foo.Component.self, key: childKey("cell-\(idx)"))
      nodes.append(node)
    }
    table.props.sections.append(UITableComponentProps.Section(components: nodes))
    return table.asNode()
  }
}
