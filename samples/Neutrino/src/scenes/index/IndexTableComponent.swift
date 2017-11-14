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

    private func cellKey(for index: Int) -> String {
      return childKey("index-\(index)")
    }
  }

  class IndexCell: UIStatelessComponent<UI.Props.IndexCell> {
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      let props = self.props
      // The main content view.
      let content = UINode<UIView> { config in
        let background = props.isHighlighted ? Palette.primaryAccent : Palette.primary
        config.set(\UIView.backgroundColor, context.stylesheet.palette(background))
        config.set(\UIView.yoga.width, config.canvasSize.width)
        config.set(\UIView.yoga.padding, 16)
      }
      // The cell title.
      let title = UINode<UILabel>(reuseIdentifier: "title") { config in
        config.set(\UILabel.text, props.title)
        config.set(\UILabel.numberOfLines, 0)
        config.set(\UILabel.font, context.stylesheet.typography(Font.text))
        config.set(\UILabel.textColor, context.stylesheet.palette(Palette.white))
      }
      return content.children([title])
    }
  }
}


