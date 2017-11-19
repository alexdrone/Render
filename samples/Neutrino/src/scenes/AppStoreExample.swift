import UIKit
import RenderNeutrino

extension UI.States {
  class AppStoreEntry: UIState {
    var expanded: Bool = false
    var counter: Int = 6
  }
}

extension UI.Props {
  class AppStoreEntry: UIProps {
    var title: String = "NEUTRINO "
    var desc: String = "A Render Neutrino component."
    var image: UIImage = UIImage(named: "game")!
  }
}

extension UI.Components {

  class AppStoreEntry: UIComponent<UI.States.AppStoreEntry, UI.Props.AppStoreEntry> {
    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      // The main content view.
      return UINode<UIImageView>(configure: configureContentView).children([
        // An dark overlay.
        UINode<UIView>(configure: configureOverlay),
        // Lays out the icon and the title.
        UINode<UIView>(configure: configureRowContainer).children([
          UI.Fragments.Polygon(context: context,
                               configure: configureShape),
          UI.Fragments.Text(text: "\(props.title)#\(state.counter)",
                            configure: configureLabel),
        ]),
        // Entry description (shown when the component is expanded).
        UINode<UIView>(configure: configureDescriptionContainer).children([
          UI.Fragments.Text(text: props.desc,
                            configure: configureDescriptionLabel),
          UI.Fragments.Button(text: "Increase",
                              backgroundColor: context.stylesheet.palette(Palette.white),
                              onTouchUpInside: { [weak self] in self?.onIncrease() })
        ]),
        // Touch overlay that covers the whole component.
        UI.Fragments.TapRecognizer(onTouchUpInside: { [weak self] in self?.onToggleExpand() },
                                   configure: configureTappableView),
      ])
    }

    private func onToggleExpand() -> Void {
      state.expanded = !state.expanded
      setNeedsRender(options: [.animateLayoutChanges(animator: self.defaultAnimator())])
    }

    private func onIncrease() -> Void {
      state.counter = state.counter >= 12 ? 4 : state.counter + 2
      setNeedsRender()
    }

    // MARK: - Containers

    // The main content view with the entry background image.
    private func configureContentView(configuration: UINode<UIImageView>.Configuration) {
      let margin: CGFloat = state.expanded ? 0 : MarginPreset.medium.cgFloatValue
      let height: CGFloat = state.expanded ? 256 : 128
      let radius: CornerRadiusPreset = state.expanded ? .none : .cornerRadius4
      configuration.set(\UIImageView.image, props.image)
      configuration.set(\UIImageView.contentMode, .scaleAspectFill)
      configuration.set(\UIImageView.yoga.width, configuration.canvasSize.width - margin * 2)
      // The corner radius is being animated on change.
      configuration.set(\UIImageView.cornerRadius, radius.cgFloatValue, animator: defaultAnimator())
      configuration.set(\UIImageView.yoga.height, height)
      configuration.set(\UIImageView.yoga.margin, margin)
      configuration.set(\UIImageView.yoga.marginTop, 64)
      configuration.set(\UIImageView.isUserInteractionEnabled, true)
    }

    // Wrapper around the icon and the title.
    private func configureRowContainer(configuration: UINode<UIView>.Configuration) {
      configuration.set(\UIView.backgroundColor, .clear)
      // The container takes all of the parent's width and 80% of the height.
      configuration.set(\UIView.yoga.percent.width, 100%)
      configuration.set(\UIView.yoga.percent.height, 80%)
      configuration.set(\UIView.yoga.padding, MarginPreset.default.cgFloatValue)
      // Lays out the children horizontally.
      configuration.set(\UIView.yoga.flexDirection, .row)
    }

    // MARK: - Description

    // The dark banner at the bottom of the component showing the entry description.
    private func configureDescriptionContainer(configuration: UINode<UIView>.Configuration) {
      // The container takes all of the parent's width and 20% of the height.
      configuration.set(\UIView.yoga.percent.width, 100%)
      configuration.set(\UIView.yoga.percent.height, 20%)
      configuration.set(\UIView.yoga.padding, MarginPreset.small.cgFloatValue)
      configuration.set(\UIView.yoga.justifyContent, .center)
      configuration.set(\UIView.yoga.flexDirection, .row)
      configuration.set(\UIView.backgroundColor, context?.stylesheet.palette(Palette.text))
      // The alpha is animated on change.
      configuration.set(\UIView.alpha, !state.expanded ? 0 : 1, animator: defaultAnimator())
    }

    // The description text.
    private func configureDescriptionLabel(configuration: UINode<UILabel>.Configuration) {
      configuration.set(\UILabel.font, context?.stylesheet.typography(Font.small))
      configuration.set(\UILabel.textColor, context?.stylesheet.palette(Palette.white))
      // The alpha is animated on change.
      configuration.set(\UILabel.alpha, !state.expanded ? 0 : 1, animator: defaultAnimator())
      configuration.view.yoga.flex()
    }

    // MARK: - Title

    // The main title.
    private func configureLabel(configuration: UINode<UILabel>.Configuration) {
      let font: Font = state.expanded ? .mediumBold : .medium
      configuration.set(\UILabel.yoga.height, HeightPreset.medium.cgFloatValue)
      configuration.set(\UILabel.font, context?.stylesheet.typography(font))
      configuration.set(\UILabel.textColor, context?.stylesheet.palette(Palette.white))
    }

    // MARK: - Shape

    private func configureShape(configuration: UINode<UIPolygonView>.Configuration) {
      let rotation = configuration.view.transform.rotated(by: 90 / 180.0 * CGFloat.pi)
      configuration.set(\UIPolygonView.numberOfSides, state.counter)
      configuration.set(\UIPolygonView.transform,
                        state.expanded ? .identity : rotation,
                        animator: defaultAnimator())
    }

    // MARK: - Overlays

    // Overlay that darkens the background image.
    private func configureOverlay(configuration: UINode<UIView>.Configuration) {
      let alpha: CGFloat = state.expanded ? 0.2 : 0.5
      let bkg = UIColor.black.withAlphaComponent(alpha)
      configuration.set(\UIView.backgroundColor, bkg, animator: defaultAnimator())
      configureAbsoluteOverlay(configuration: configuration)
    }

    // Touch overlay that covers the whole component.
    private func configureTappableView(configuration: UINode<UIView>.Configuration) {
      configureAbsoluteOverlay(configuration: configuration)
      configuration.set(\UIView.yoga.percent.height, 80%)
    }

    // The overlays have position '.absolute' in order to cover all of the parent's space.
    private func configureAbsoluteOverlay(configuration: UINode<UIView>.Configuration) {
      configuration.set(\UIView.yoga.percent.width, 100%)
      configuration.set(\UIView.yoga.percent.height, 100%)
      configuration.set(\UIView.yoga.position, .absolute)
    }

    // MARK: - Animator

    private func defaultAnimator() -> UIViewPropertyAnimator {
      return UIViewPropertyAnimator(duration: 0.6, dampingRatio: 0.6, animations: nil)
    }
  }
}
