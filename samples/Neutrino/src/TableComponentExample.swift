import UIKit
import RenderNeutrino

extension UI.Components {
  class FooTable: UIPureComponent {
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      // Retrieve the table component with the given key.
      let table = childComponent(UIDefaultTableComponent.self, key: childKey("table"))
      // Configure the client.
      table.props.configuration = { config in
        config.set(\UITableView.backgroundColor, Color.black)
      }
      // Builds a section with 100 'Foo.Component' cells and a header.
      let section = UITableComponentProps.Section(
        cells: Array(0..<20).map { idx in
          table.cell(UI.Components.JsCounter.self, key: childKey("cell-\(idx)"))
        },
        header: table.header(UI.Components.HeaderComponent.self))
      // Sets the props section.
      table.props.sections = [section]
      // Returns the component node.
      return table.asNode()
    }
  }
}

extension UI.Components {
  class HeaderComponent: UIPureComponent {
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
}
