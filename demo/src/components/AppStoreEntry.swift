import UIKit
import RenderNeutrino

struct AppStoreEntry {

  class State: UIState {
    var expanded: Bool = false
    var counter: Int = 0
  }

  class Props: UIProps {
    var title: String = "Neutrino"
    var desc: String = "A Render Neutrino component."
    var image: UIImage? = UIImage(named: "game")
  }

  class Component: UIComponent<State, Props> {
    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {

      return UINode<UIView>(layoutSpec: configureMainView).children([
        // The main content view.
        UINode<UIImageView>(layoutSpec: configureContentView).children([
          // An dark overlay.
          UINode<UIView>(layoutSpec: configureOverlay),
          // Lays out the icon and the title.
          UINode<UIView>(layoutSpec: configureRowContainer).children([
            makePolygon(),
            makeLabel(text: "\(props.title)#\(state.counter)",
                      layoutSpec: configureLabel),
            ]),
          // Entry description (shown when the component is expanded).
          UINode<UIView>(layoutSpec: configureDescriptionContainer).children([
            makeLabel(text: props.desc,
                      layoutSpec: configureDescriptionLabel),
            makeButton(text: "Increase",
                       onTouchUpInside: { [weak self] in self?.onIncrease() })
            ]),
          // Touch overlay that covers the whole component.
          makeTapRecognizer(onTouchUpInside: { [weak self] in self?.onToggleExpand() },
                            layoutSpec: configureTappableView),
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

    private func configureMainView(spec: UINode<UIView>.LayoutSpec) {
      spec.set(\UIView.backgroundColor, S.Palette.primary.color)
    }

    // The main content view with the entry background image.
    private func configureContentView(spec: UINode<UIImageView>.LayoutSpec) {
      let margin: CGFloat = state.expanded ? 0 : 8
      let height: CGFloat = state.expanded ? 256 : 128
      let radius: CGFloat = state.expanded ? 0 : 8
      spec.set(\UIImageView.image, props.image)
      spec.set(\UIImageView.contentMode, .scaleAspectFill)
      spec.set(\UIImageView.yoga.width, spec.canvasSize.width - margin*2)
      spec.set(\UIImageView.yoga.height, height)
      spec.set(\UIImageView.yoga.margin, margin)
      // The corner radius is being animated on change.
      spec.set(\UIImageView.cornerRadius, radius, animator: defaultAnimator())
      spec.set(\UIImageView.isUserInteractionEnabled, true)
    }

    // Wrapper around the icon and the title.
    private func configureRowContainer(spec: UINode<UIView>.LayoutSpec) {
      spec.set(\UIView.backgroundColor, .clear)
      // The container takes all of the parent's width and 80% of the height.
      spec.set(\UIView.yoga.percent.width, 100%)
      spec.set(\UIView.yoga.percent.height, 80%)
      spec.set(\UIView.yoga.padding, 4)
      // Lays out the children horizontally.
      spec.set(\UIView.yoga.flexDirection, .row)
    }

    // MARK: - Description

    // The dark banner at the bottom of the component showing the entry description.
    private func configureDescriptionContainer(spec: UINode<UIView>.LayoutSpec) {
      // The container takes all of the parent's width and 20% of the height.
      spec.set(\UIView.yoga.percent.width, 100%)
      spec.set(\UIView.yoga.percent.height, 20%)
      spec.set(\UIView.yoga.padding, S.Margin.xsmall.cgFloat)
      spec.set(\UIView.yoga.justifyContent, .center)
      spec.set(\UIView.yoga.flexDirection, .row)
      spec.set(\UIView.backgroundColor, S.Palette.text.color)
      // The alpha is animated on change.
      spec.set(\UIView.alpha, !state.expanded ? 0 : 1, animator: defaultAnimator())
    }

    // The description text.
    private func configureDescriptionLabel(spec: UINode<UILabel>.LayoutSpec) {
      spec.set(\UILabel.font, S.Typography.small.font)
      spec.set(\UILabel.textColor, S.Palette.white.color)
      // The alpha is animated on change.
      spec.set(\UILabel.alpha, !state.expanded ? 0 : 1, animator: defaultAnimator())
      spec.set(\UILabel.yoga.flexGrow, 1)
      spec.set(\UILabel.yoga.flexShrink, 1)
    }

    // MARK: - Title

    // The main title.
    private func configureLabel(spec: UINode<UILabel>.LayoutSpec) {
      let font: UIFont = state.expanded ? S.Typography.mediumBold.font : S.Typography.medium.font
      spec.set(\UILabel.yoga.height, 32)
      spec.set(\UILabel.yoga.width, 256)
      spec.set(\UILabel.font, font)
      spec.set(\UILabel.textColor, S.Palette.white.color)
    }

    // MARK: - Overlays

    // Overlay that darkens the background image.
    private func configureOverlay(spec: UINode<UIView>.LayoutSpec) {
      let alpha: CGFloat = state.expanded ? 0.2 : 0.5
      let bkg = UIColor.black.withAlphaComponent(alpha)
      spec.set(\UIView.backgroundColor, bkg, animator: defaultAnimator())
      configureAbsoluteOverlay(spec: spec)
    }

    // Touch overlay that covers the whole component.
    private func configureTappableView(spec: UINode<UIView>.LayoutSpec) {
      configureAbsoluteOverlay(spec: spec)
      spec.set(\UIView.yoga.percent.height, 80%)
    }

    // The overlays have position '.absolute' in order to cover all of the parent's space.
    private func configureAbsoluteOverlay(spec: UINode<UIView>.LayoutSpec) {
      spec.set(\UIView.yoga.percent.width, 100%)
      spec.set(\UIView.yoga.percent.height, 100%)
      spec.set(\UIView.yoga.position, .absolute)
    }

    // MARK: - Animator

    private func defaultAnimator() -> UIViewPropertyAnimator {
      return UIViewPropertyAnimator(duration: 0.6, dampingRatio: 0.6, animations: nil)
    }
  }
}

// MARK: - Private

fileprivate func makeLabel(text: String,
                           layoutSpec: UINode<UILabel>.LayoutSpecClosure?=nil) -> UINode<UILabel> {
  return UINode<UILabel> { config in
    config.set(\UILabel.text, text)
    config.set(\UILabel.numberOfLines, 0)
    config.set(\UILabel.textColor, S.Palette.white.color)
    layoutSpec?(config)
  }
}

fileprivate func makeButton(reuseIdentifier: String = "button",
                            text: String,
                            onTouchUpInside: @escaping () -> Void = { },
                            layoutSpec: UINode<UIButton>.LayoutSpecClosure?=nil) -> UINode<UIButton> {
  func makeButton() -> UIButton {
    let view = UIButton()
    view.backgroundColorImage = S.Palette.white.color
    view.textColor = S.Palette.primary.color
    view.depthPreset = .depth1
    view.cornerRadius = 2
    view.yoga.padding = S.Margin.small.cgFloat
    view.titleLabel?.font = S.Typography.smallBold.font
    return view
  }
  return UINode<UIButton>(reuseIdentifier: reuseIdentifier, create: makeButton) { config in
    config.view.setTitle(text, for: .normal)
    config.view.onTap { _ in onTouchUpInside() }
  }
}

fileprivate func makeTapRecognizer(reuseIdentifier: String = "tapRecognizer",
                                   onTouchUpInside: @escaping () -> Void = { },
                                   layoutSpec: UINode<UIView>.LayoutSpecClosure?=nil)->UINode<UIView> {
  return UINode<UIView>(reuseIdentifier: reuseIdentifier) { config in
    config.view.onTap { _ in onTouchUpInside() }
    layoutSpec?(config)
  }
}
