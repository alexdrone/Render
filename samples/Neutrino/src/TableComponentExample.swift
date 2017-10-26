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

    var section = UITableComponentProps.Section(cells: cells)
    section.header = table.header(HeaderComponent.self)
    table.props.sections.append(section)

    return table.asNode()
  }
}

class HeaderComponent: UIComponent<UINilState, UINilProps> {
  override func render(context: UIContextProtocol) -> UINodeProtocol {
    return UINode<UILabel>() { config in
      config.set(\UILabel.text, "Welcome to Render-Neutrino")
      config.set(\UILabel.font, Typography.mediumBold)
      config.set(\UILabel.textAlignment, .center)
      config.set(\UILabel.yoga.width, config.canvasSize.width)
      config.set(\UILabel.yoga.padding, 16)
      config.set(\UILabel.backgroundColor, Color.red)
      config.set(\UILabel.textColor, Color.white)

    }
  }
}
