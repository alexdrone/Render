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
        cells: Array(0..<100).map { idx in
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

    override func requiredJsFragments() -> [String] {
      return ["Fragments"]
    }

    override func render(context: UIContextProtocol) -> UINodeProtocol {
      return context.jsBridge.buildFragment(function: "TableHeader",
                                            props: UINilProps.nil,
                                            canvasSize: context.screen.canvasSize)
    }
  }
}
