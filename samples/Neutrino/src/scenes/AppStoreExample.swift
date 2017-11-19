import UIKit
import RenderNeutrino

extension UI.States {
  class AppStoreEntry: UIState {
    var expanded: Bool = false
    var counter: Int = 0
  }
}

extension UI.Props {
  class AppStoreEntry: UIProps {
    var title: String = "TERRAFORM "
    var image: UIImage = UIImage(named: "game")!
  }
}

extension UI.Components {

  class AppStoreEntry: UIComponent<UI.States.AppStoreEntry, UI.Props.AppStoreEntry> {

    override func render(context: UIContextProtocol) -> UINodeProtocol {
      return UINode<UIImageView>(configure: configureContentView).children([
        UINode<UIView>(configure: configureOverlay),
        UINode<UIView>(configure: configureTappableView).children([
          UI.Fragments.Polygon(context: context),
          UI.Fragments.Text(text: "\(props.title)#\(state.counter)", configure: configureLabel)
        ])
      ])
    }

    private func configureOverlay(configuration: UINode<UIView>.Configuration) {
      let alpha: CGFloat = state.expanded ? 0.2 : 0.5
      let bkg = UIColor.black.withAlphaComponent(alpha)
      configuration.set(\UIView.backgroundColor, bkg, animator: defaultAnimator())
      configuration.set(\UIView.yoga.percent.width, 100%)
      configuration.set(\UIView.yoga.percent.height, 100%)
      configuration.set(\UIView.yoga.position, .absolute)
    }

    private func configureTappableView(configuration: UINode<UIView>.Configuration) {
      configuration.set(\UIView.backgroundColor, .clear)
      configuration.set(\UIView.yoga.percent.width, 100%)
      configuration.set(\UIView.yoga.percent.height, 100%)
      configuration.set(\UIView.yoga.padding, MarginPreset.default.cgFloatValue)
      configuration.set(\UIView.yoga.flexDirection, .row)
      configuration.set(\UIView.yoga.alignItems, .flexStart)

      configuration.view.onTap { [weak self] _ in
        guard let `self` = self else { return }
        self.state.expanded = !self.state.expanded
        self.state.counter += 1
        self.setNeedsRender(options: [.animateLayoutChanges(animator: self.defaultAnimator())])
      }
    }

    private func configureContentView(configuration: UINode<UIImageView>.Configuration) {
      let animator = defaultAnimator()
      let margin: CGFloat = state.expanded ? 0 : MarginPreset.medium.cgFloatValue
      let height: CGFloat = state.expanded ? 256 : 128
      let radius: CornerRadiusPreset = state.expanded ? .none : .cornerRadius4
      configuration.set(\UIImageView.image, props.image)
      configuration.set(\UIImageView.contentMode, .scaleAspectFill)
      configuration.set(\UIImageView.cornerRadius, radius.cgFloatValue, animator: animator)
      configuration.set(\UIImageView.depthPreset, .depth2)
      configuration.set(\UIImageView.yoga.width, configuration.canvasSize.width - margin * 2)
      configuration.set(\UIImageView.yoga.height, height, animator: animator)
      configuration.set(\UIImageView.yoga.margin, margin, animator: animator)
      configuration.set(\UIImageView.yoga.marginTop, 64)
      configuration.set(\UIImageView.isUserInteractionEnabled, true)
    }

    private func configureLabel(configuration: UINode<UILabel>.Configuration) {
      configuration.set(\UILabel.yoga.height, HeightPreset.medium.cgFloatValue)
      configuration.set(\UILabel.font, context?.stylesheet.typography(Font.mediumBold))
      configuration.set(\UILabel.textColor, context?.stylesheet.palette(Palette.white))
    }

    private func defaultAnimator() -> UIViewPropertyAnimator {
      return UIViewPropertyAnimator(duration: 0.6, dampingRatio: 0.6, animations: nil)
    }
  }
}
