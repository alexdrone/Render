import UIKit
import RenderNeutrino

extension UI.States {
  class IndexTable: UIState {
  }
}

extension UI.Props {
  class IndexTable: UIProps {
    var titles: [IndexCell] = []
  }
  class IndexCell: UITableCellProps { }
}

extension UI.Components {

  class IndexTable: UIComponent<UI.States.IndexTable, UI.Props.IndexTable> {
    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      // Retrieve the table component with the given key.
      let table = childComponent(UIDefaultTableComponent.self, key: childKey("table"))
      // Configure the table.
      table.props.configuration = { config in
        config.set(\UITableView.backgroundColor, context.stylesheet.palette(Palette.secondary))
      }
      // Builds the section.
      let section = UITableComponentProps.Section(cells: props.titles.enumerated().map { i, props in
        return table.cell(IndexCell.self, key: cellKey(for: i), props: props)
      })
      table.props.sections = [section]
      // Returns the component node.
      return table.asNode()
    }

    // Helper function that returns the key for a cell at a given index.
    private func cellKey(for index: Int) -> String {
      return childKey("index-\(index)")
    }
  }

  class IndexCell: UIStatelessComponent<UI.Props.IndexCell> {
    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      let props = self.props
      let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn, animations: nil)
      // The cell content view.
      let content = UICommons.RowContainer(padding: 18, widthRatio: 1) { config in
        let background = context.stylesheet.palette(
          props.isHighlighted ? Palette.primaryAccent : Palette.primary)
        /// Animates the background color when the cell is selected.
        config.set(\UIView.backgroundColor, background, animator: animator)
        config.set(\UIView.depthPreset, props.isHighlighted ? .depth2 : .none)
      }
      // A custom fragment.
      let shape = UI.Fragments.Polygon(context: context)
      // The two labels.
      let font = context.stylesheet.typography(props.isHighlighted ? Font.smallBold : Font.small)
      let labels = UICommons.ColumnContainer() { config in
        // Ensure the label container is center aligned.
        config.set(\UIView.yoga.justifyContent, .center)
      }.children([
        UICommons.Text(reuseIdentifier: "title",
                       text: props.title,
                       font: font,
                       color: context.stylesheet.palette(Palette.white)),
        UICommons.Text(reuseIdentifier: "subtitle",
                       text: props.subtitle,
                       font: font,
                       color: context.stylesheet.palette(Palette.accentText))
      ])
      return content.children([shape, labels])
    }
  }
}

extension UI.Fragments {
  /// Used as shape for many of the examples.
  static func Polygon(context: UIContextProtocol) -> UINodeProtocol {
    return UINode<UIPolygonView> { config in
      let size = HeightPreset.medium.cgFloatValue
      config.set(\UIPolygonView.foregroundColor, context.stylesheet.palette(Palette.white))
      config.set(\UIPolygonView.yoga.width, size)
      config.set(\UIPolygonView.yoga.height, size)
      config.set(\UIPolygonView.yoga.marginRight, 16)
      config.set(\UIPolygonView.depthPreset, .depth1)
    }
  }
}
