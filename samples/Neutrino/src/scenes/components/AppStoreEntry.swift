import UIKit
import RenderNeutrino

struct AppStoreEntry {

  // MARK: - State

  class State: UIState {
    var expanded: Bool = false
    var counter: Int = 0
  }

  // MARK: - Props

  class Props: UIProps {
    var title: String = ""
    var desc: String = ""
    var image: UIImage? = nil

    static func singleCardExample() -> Props {
      let entry = Props()
      entry.title = "Neutrino"
      entry.desc = "A Render Neutrino component."
      entry.image = UIImage(named: "game")
      return entry
    }

    static func listCardExample() -> Props {
      let entry = Props()
      entry.title = "Item"
      entry.desc = "A component cell."
      entry.image = UIImage(named: "game")
      return entry
    }
  }

  // MARK: - Component

  class Component: UIComponent<State, Props> {
    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {

      return UINode<UIView>(configure: configureMainView).children([
        // The main content view.
        UINode<UIImageView>(configure: configureContentView).children([
          // An dark overlay.
          UINode<UIView>(configure: configureOverlay),
          // Lays out the icon and the title.
          UINode<UIView>(configure: configureRowContainer).children([
            Fragment.Polygon(),
            Fragment.Text(text: "\(props.title)#\(state.counter)",
                          configure: configureLabel),
            ]),
          // Entry description (shown when the component is expanded).
          UINode<UIView>(configure: configureDescriptionContainer).children([
            Fragment.Text(text: props.desc,
                              configure: configureDescriptionLabel),
            Fragment.Button(text: "Increase",
                            backgroundColor: Palette.white.color,
                            onTouchUpInside: { [weak self] in self?.onIncrease() })
            ]),
          // Touch overlay that covers the whole component.
          Fragment.TapRecognizer(onTouchUpInside: { [weak self] in self?.onToggleExpand() },
                                 configure: configureTappableView),
          ])
      ])
    }

    // Executed when the card is tapped.
    private func onToggleExpand() -> Void {
      state.expanded = !state.expanded
      setNeedsRender(options: [.animateLayoutChanges(animator: self.defaultAnimator())])
    }

    // Executed when the 'Increase' button is tapped.
    private func onIncrease() -> Void {
      state.counter += 1
      setNeedsRender()
    }

    // MARK: - Containers

    private func configureMainView(configuration: UINode<UIView>.Configuration) {
      configuration.set(\UIView.backgroundColor, Palette.secondary.color)
    }

    // The main content view with the entry background image.
    private func configureContentView(configuration: UINode<UIImageView>.Configuration) {
      let margin: CGFloat = state.expanded ? 0 : 8
      let height: CGFloat = state.expanded ? 256 : 128
      let radius: CornerRadiusPreset = state.expanded ? .none : .cornerRadius4
      configuration.set(\UIImageView.image, props.image)
      configuration.set(\UIImageView.contentMode, .scaleAspectFill)
      configuration.set(\UIImageView.yoga.width, configuration.canvasSize.width - margin*2)
      configuration.set(\UIImageView.yoga.height, height)
      configuration.set(\UIImageView.yoga.margin, margin)
      // The corner radius is being animated on change.
      configuration.set(\UIImageView.cornerRadius, radius.cgFloatValue, animator: defaultAnimator())
      configuration.set(\UIImageView.isUserInteractionEnabled, true)
    }

    // Wrapper around the icon and the title.
    private func configureRowContainer(configuration: UINode<UIView>.Configuration) {
      configuration.set(\UIView.backgroundColor, .clear)
      // The container takes all of the parent's width and 80% of the height.
      configuration.set(\UIView.yoga.percent.width, 100%)
      configuration.set(\UIView.yoga.percent.height, 80%)
      configuration.set(\UIView.yoga.padding, 4)
      // Lays out the children horizontally.
      configuration.set(\UIView.yoga.flexDirection, .row)
    }

    // MARK: - Description

    // The dark banner at the bottom of the component showing the entry description.
    private func configureDescriptionContainer(configuration: UINode<UIView>.Configuration) {
      // The container takes all of the parent's width and 20% of the height.
      configuration.set(\UIView.yoga.percent.width, 100%)
      configuration.set(\UIView.yoga.percent.height, 20%)
      configuration.set(\UIView.yoga.padding, 2)
      configuration.set(\UIView.yoga.justifyContent, .center)
      configuration.set(\UIView.yoga.flexDirection, .row)
      configuration.set(\UIView.backgroundColor, Palette.text.color)
      // The alpha is animated on change.
      configuration.set(\UIView.alpha, !state.expanded ? 0 : 1, animator: defaultAnimator())
    }

    // The description text.
    private func configureDescriptionLabel(configuration: UINode<UILabel>.Configuration) {
      configuration.set(\UILabel.font, Typography.small.font)
      configuration.set(\UILabel.textColor, Palette.white.color)
      // The alpha is animated on change.
      configuration.set(\UILabel.alpha, !state.expanded ? 0 : 1, animator: defaultAnimator())
      configuration.set(\UILabel.yoga.flexGrow, 1)
      configuration.set(\UILabel.yoga.flexShrink, 1)
    }

    // MARK: - Title

    // The main title.
    private func configureLabel(configuration: UINode<UILabel>.Configuration) {
      let font: UIFont = state.expanded ? Typography.mediumBold.font : Typography.medium.font
      configuration.set(\UILabel.yoga.height, 32)
      configuration.set(\UILabel.font, font)
      configuration.set(\UILabel.textColor, Palette.white.color)
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
