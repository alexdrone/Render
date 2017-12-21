import UIKit
import RenderNeutrino

struct AppStoreList {

  class State: UIState { }

  class Props: UIProps {
    let numberOfItems: Int = 200
  }

  class Component: UIComponent<State, Props> {
    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      // Retrieve the table component with the given key.
      let table = childComponent(UIDefaultTableComponent.self, key: childKey("table"))
      // Configure the table.
      table.props.configuration = { config in
        config.set(\UITableView.backgroundColor, Palette.secondary.color)
      }
      // Builds the section.
      let cells = Array(0..<props.numberOfItems).map { idx in
        return table.cell(AppStoreEntry.Component.self,
                          key: cellKey(for: idx),
                          props: AppStoreEntry.Props())
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

