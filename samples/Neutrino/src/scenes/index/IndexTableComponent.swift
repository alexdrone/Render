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

  class IndexCell: UIProps {
    var title = String()
    var onCellSelected: () -> Void = { }

    required init() { }
    init(title: String, onCellSelected: @escaping () -> Void) {
      self.title = title
      self.onCellSelected = onCellSelected
    }
  }
}

extension UI.Components {

  class IndexTable: UIComponent<UI.States.IndexTable, UI.Props.IndexTable> {
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      // Retrieve the table component with the given key.
      let table = childComponent(UIDefaultTableComponent.self, key: childKey("table"))
      // Configure the table.
      table.props.configuration = { config in
        config.set(\UITableView.backgroundColor, Palette.white.in(context: context))
      }
      // Builds the section.
      let section = UITableComponentProps.Section(cells: props.titles.enumerated().map { i, props in
        // Construct a cell descriptors through the table component.
        let cell = table.cell(IndexCell.self, key: cellKey(for: i), props: props)
        cell.selectionStyle = .default
        return cell
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
        config.set(\UIView.backgroundColor, Palette.blue.in(context: context))
        config.set(\UIView.yoga.width, config.canvasSize.width)
        config.set(\UIView.yoga.padding, 16)
        // Register and action for the tap event.
        config.view.onTap { [weak self] _ in self?.props.onCellSelected()
        }
      }
      // The cell title.
      let title = UINode<UILabel>(reuseIdentifier: "title") { config in
        config.set(\UILabel.text, props.title)
        config.set(\UILabel.numberOfLines, 0)
        config.set(\UILabel.font, Font.text.in(context: context))
        config.set(\UILabel.textColor, Palette.green.in(context: context))
      }
      return content.children([title])
    }
  }
}


