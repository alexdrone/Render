import UIKit
import RenderNeutrino

struct Index {

  class State: UIState { }

  class Props: UIProps {
    var titles: [CellProps] = []
  }

  class CellProps: UITableCellProps { }

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
      let section = UITableComponentProps.Section(cells: props.titles.enumerated().map { i, props in
        return table.cell(Cell.self, key: childKey(Cell.self, i), props: props)
      })
      table.props.sections = [section]
      // Returns the component node.
      return table.asNode()
    }
  }

  class Cell: UIStatelessComponent<CellProps> {
    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      // The cell content view.
      return Fragment.Row(widthRatio: 1, configure: configureContentView).children([
        Fragment.Polygon(),
        Fragment.Column() { config in
          // Ensure the label container is center aligned.
          config.set(\UIView.yoga.justifyContent, .center)
        }.children([
            Fragment.Text(reuseIdentifier: "title",
                              text: props.title,
                              configure: configureLabel),
            Fragment.Text(reuseIdentifier: "subtitle",
                              text: props.subtitle,
                              configure: configureLabel)
          ])
      ])
    }

    private func configureContentView(configuration: UINode<UIView>.Configuration) {
      let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn, animations: nil)
      let bkg = props.isHighlighted ? Palette.primaryAccent.color : Palette.primary.color
      /// Animates the background color when the cell is selected.
      configuration.set(\UIView.backgroundColor, bkg, animator: animator)
      // You can configure your view both using the keyPath accessor (that offer an optional
      // animator parameter), or by accessing to the 'renderedView' manually.
      configuration.view.yoga.padding = MarginPreset.default.cgFloatValue
      configuration.view.depthPreset = props.isHighlighted ? .depth2 : .none
    }

    private func configureLabel(configuration: UINode<UILabel>.Configuration) {
      let font = props.isHighlighted ? Typography.smallBold.font : Typography.small.font
      configuration.view.font = font
      configuration.view.textColor = Palette.white.color
      configuration.view.yoga.margin = MarginPreset.tiny.cgFloatValue
    }
  }
}
