import RenderNeutrino

struct Track {

  class TrackProps: UIProps {
    var id: String = NSUUID().uuidString.lowercased()
    var title: String = Random.sentence()
    var cover: UIImage? = Random.image()
  }

  class TrackComponent: UIComponent<UINilState, TrackProps> {

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

  class NavigationBar: UINavigationBarComponent {
    // Example of additional payload.
    class UserInfo: NSObject {
      let cover: UIImage? = Random.image()
    }

    /// Entrypoint to override in subclasses.
    override func overrideStyle(_ style: UINavigationBarDefaultStyle) {
      var style = UINavigationBarDefaultStyle.default
      style.backgroundColor = S.TrackPalette.black.color
      style.heightWhenExpanded = 232
      style.tintColor = S.TrackPalette.green.color
      props.style = style
    }

    // Override the title fragment.
    override func renderTitle() -> UINodeProtocol {
      let main = UINode<UIView>(styles: S.TrackNavigationBar_main.style) { configuration in
        configuration.view.yoga.percent.width = 50%
        configuration.view.yoga.percent.height = 100%
      }
      let circle = UINode<UIView>(styles: S.TrackNavigationBar_circle.style) { configuration in
        let s = min(configuration.canvasSize.width/2, self.state.height) - 8
        configuration.view.yoga.width = s
        configuration.view.yoga.height = s
        configuration.view.cornerRadius = s/2
        configuration.view.alpha = pow(self.props.scrollProgress(currentHeight: self.state.height), 3)
      }
      let button = UINode<UIButton>(styles: S.TrackNavigationBar_button.style) { configuration in
        configuration.view.yoga.position = .absolute
        configuration.view.yoga.top = self.state.height - 16
      }
      return main.children([
        circle,
        button
      ])
    }
  }

}
