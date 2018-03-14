import UIKit
import RenderNeutrino

struct Index {

  class CellProps: UITableCellProps { }

  class Cell: UIStatelessComponent<CellProps> {
    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      // The cell content view.
      return UINode<UIView>(layoutSpec: configureContentView).children([
        makePolygon(),
        UINode<UIView> { config in
          // Ensure the label container is center aligned.
          config.set(\UIView.yoga.justifyContent, .center)
          config.set(\UIView.yoga.flexGrow, 1)
          config.set(\UIView.yoga.flexShrink, 1)
        }.children([
            label(text: props.title, bold: true),
            label(text: props.subtitle),
          ])
      ])
    }

    private func configureContentView(spec: UINode<UIView>.LayoutSpec) {
      let animator = UIViewPropertyAnimator(duration: 0.6, curve: .easeIn, animations: nil)
      let bkg = props.isHighlighted ? S.Palette.primaryAccent.color : S.Palette.primary.color
      /// Animates the background color when the cell is selected.
      spec.set(\UIView.yoga.flexDirection, .row)
      spec.set(\UIView.yoga.width, spec.canvasSize.width)
      spec.set(\UIView.yoga.padding, S.Margin.medium.cgFloat)
      spec.set(\UIView.backgroundColor, bkg, animator: animator)
      // You can configure your view both using the keyPath accessor (that offer an optional
      // animator parameter), or by accessing to the 'renderedView' manually.
      spec.view.yoga.padding = S.Margin.medium.cgFloat
      spec.view.depthPreset = props.isHighlighted ? .depth2 : .none
    }

    private func label(text: String, bold: Bool = false) -> UINode<UILabel> {
      return UINode<UILabel> { spec in
        spec.set(\UILabel.text, text)
        spec.set(\UILabel.numberOfLines, 0)
        spec.set(\UILabel.font, S.Typography.small.font)
        spec.set(\UILabel.textColor, S.Palette.white.color)
        spec.set(\UILabel.yoga.margin, S.Margin.xsmall.cgFloat)
      }
    }
  }
}
