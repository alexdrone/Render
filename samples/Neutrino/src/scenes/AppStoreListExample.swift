import UIKit
import RenderNeutrino

extension UI.States {
  class AppStoreList: UIState {
  }
}

extension UI.Components {

  class AppStoreList: UIComponent<UI.States.AppStoreList, UINilProps> {
    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      // Retrieve the table component with the given key.
      let table = childComponent(UIDefaultTableComponent.self, key: childKey("table"))
      // Configure the table.
      table.props.configuration = { config in
        config.set(\UITableView.backgroundColor, context.stylesheet.palette(Palette.secondary))
      }
      // Builds the section.
      let cells = Array(0..<20).map { idx in
        return table.cell(AppStoreEntry.self, key: cellKey(for: idx))
      }
      let section = UITableComponentProps.Section(cells: cells)
      table.props.sections = [section]

      // Returns the component node.
      return table.asNode()
    }

    // Helper function that returns the key for a cell at a given index.
    private func cellKey(for index: Int) -> String {
      return childKey("appstorelist-\(index)")
    }
  }
}
