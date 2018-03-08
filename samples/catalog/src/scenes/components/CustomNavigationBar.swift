import RenderNeutrino

struct Track {

  class NavigationBar: UINavigationBarComponent {
    // Example of additional payload.
    class UserInfo: NSObject {
      let cover: UIImage? = Random.image()
      var elaspedTime: Int = -1
      var timer: Timer? = nil
    }

    /// Entrypoint to override in subclasses.
    /// If your app define a custom navigation bar component, this is the right place to change
    /// global appearance properties.
    override func overrideStyle(_ style: UINavigationBarDefaultStyle) {
      var style = UINavigationBarDefaultStyle.default
      style.backgroundColor = S.TrackPalette.lightBlack.color
      style.heightWhenExpanded = 232
      style.tintColor = S.TrackPalette.green.color
      props.style = style
    }

    // Override the title fragment (the body of the navigtion bar).
    override func renderTitle() -> UINodeProtocol {
      let main = UINode<UIView>(styles: S.TrackNavigationBar_main.style) { configuration in
        configuration.view.yoga.percent.width = 50%
        configuration.view.yoga.percent.height = 100%
      }
      let circle = UINode<UILabel>(styles: S.TrackNavigationBar_circle.style) { configuration in
        let s = min(configuration.canvasSize.width/2, self.state.height) - 8
        configuration.view.yoga.width = s
        configuration.view.yoga.height = s
        configuration.view.cornerRadius = s/2
        configuration.view.alpha =
          pow(self.props.scrollProgress(currentHeight: self.state.height), 4)

        // The mm:ss format string.
        guard let userInfo = self.props.userInfo(as: UserInfo.self) else { return }
        var elapsedTimeString = "--"
        if userInfo.elaspedTime >= 0 {
          let e = userInfo.elaspedTime
          elapsedTimeString = String(format: "%02d:%02d", e/60, e%60)
        }
        configuration.view.text = elapsedTimeString
      }
      let button = UINode<UIButton>(styles: S.TrackNavigationBar_button.style) { configuration in
        configuration.view.yoga.position = .absolute
        configuration.view.yoga.top = self.state.height - 16
        configuration.view.onTap { [weak self] _ in  self?.didTapPlayButton() }

        // Button label.
        guard let userInfo = self.props.userInfo(as: UserInfo.self) else { return }
        let title = userInfo.elaspedTime >= 0 ? "STOP" : "PLAY"
        configuration.view.setTitle(title, for: .normal)
      }
      return main.children([
        circle,
        button
      ])
    }

    // Invoked whenever the play button is pressed.
    private func didTapPlayButton() {
      // The special 'userInfo' object can be used as a state object for the navigation bar
      // because is not transient.
      guard let userInfo = self.props.userInfo(as: UserInfo.self) else { return }
      userInfo.timer?.invalidate()
      userInfo.timer = nil

      if userInfo.elaspedTime >= 0 {
        // The timer is stopped.
        userInfo.elaspedTime = -1
        setNeedsRender()
        return
      }
      // Schedule a timer.
      userInfo.timer = Timer(timeInterval: 1, repeats: true) { [weak self]_ in
        userInfo.elaspedTime += 1
        self?.setNeedsRender()
      }

      guard let timer = userInfo.timer else { return }
      RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
    }

    // Ensure the timer is invalidated when the component is destructed.
    override func dispose() {
      if let userInfo = self.props.userInfo(as: UserInfo.self) {
        userInfo.timer?.invalidate()
      }
      super.dispose()
    }
  }

  /// Model for one the dummy track cells.
  class TrackProps: UIProps {
    var id: String = NSUUID().uuidString.lowercased()
    lazy var title: String = {
      return "unknown artist\n" + "track " + self.id.replacingOccurrences(of: "-", with: "")
    }()
    var cover: UIImage? = Random.image()
  }

  /// A simple placeholder track cell.
  class TrackComponent: UIComponent<UINilState, TrackProps> {
    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      let props = self.props
      let wrapper = UINode<UIView>(styles: S.Track_wrapper.style)
      wrapper.children([
        UINode<UIImageView>(styles: S.Track_cover.style) { configuration in
          configuration.set(\UIImageView.image, props.cover)
        },
        UINode<UILabel>(styles: S.Track_title.style) { configuration in
          configuration.set(\UILabel.text, props.title)
        }
        ])
      return wrapper
    }
  }
}
