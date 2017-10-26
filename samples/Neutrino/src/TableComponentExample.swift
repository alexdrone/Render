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
    var cells: [UICell] = []
    for idx in 0...4 {
      let cell = table.cell(Foo.Component.self, key: childKey("cell-\(idx)"))
      cells.append(cell)
    }
    table.props.sections.append(UITableComponentProps.Section(cells: cells))
    return table.asNode()
  }
}
