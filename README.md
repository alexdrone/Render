# Render Neutrino [![Swift](https://img.shields.io/badge/swift-4-orange.svg?style=flat)](#) [![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg?style=flat)](#) [![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://opensource.org/licenses/MIT)

<img src="https://raw.githubusercontent.com/alexdrone/Render/master/docs/logo_new.png" width=150 alt="Render" align=right />

Render is a declarative library for building efficient UIs on iOS inspired by [React](https://github.com/facebook/react).

[Render 4.* (stable) project page](https://github.com/alexdrone/Render/tree/classic)

*Render Neutrino* is the new version of Render, re-built from the ground up.
The documentation is in progress.

* **Declarative:** Render uses a declarative API to define UI components. You simply describe the layout for your UI based on a set of inputs and the framework takes care of the rest (*diff* and *reconciliation* from virtual view hierarchy to the actual one under the hood).
* **Flexbox layout:** Render includes the robust and battle-tested Facebook's [Yoga](https://facebook.github.io/yoga/) as default layout engine.
* **Fine-grained recycling:** Any component such as a text or image can be recycled and reused anywhere in the UI.

From [Why React matters](http://joshaber.github.io/2015/01/30/why-react-native-matters/):

>  [The framework] lets us write our UIs as pure function of their states.
>
>  Right now we write UIs by poking at them, manually mutating their properties when something changes, adding and removing views, etc. This is fragile and error-prone. [...]
>
> [The framework] lets us describe our entire UI for a given state, and then it does the hard work of figuring out what needs to change. It abstracts all the fragile, error-prone code out away from us.

### Installing the framework

If you are using **CocoaPods**:


Add the following to your [Podfile](https://guides.cocoapods.org/using/the-podfile.html):

```ruby
pod 'RenderNeutrino'
```

If you are using **Carthage**:


Add the following line to your `Cartfile`:

```
github "alexdrone/Render" "master"    
```

Manually:

```
cd {PROJECT_ROOT_DIRECTORY}
curl "https://raw.githubusercontent.com/alexdrone/Render/master/bin/dist.zip" > render_neutrino_dist.zip && unzip render_neutrino_dist.zip
```

Drag `RenderNeutrino.framework` in your project and add it as an embedded binary.

### Installing the Tool-chain

(Needs admin privileges)

```
sudo chown -R $(whoami) /usr/local/bin &&
sudo curl "https://raw.githubusercontent.com/alexdrone/Render/master/tools/render-generate" > render-generate && mv render-generate /usr/local/bin/render-generate && chmod +x /usr/local/bin/render-generate &&
sudo curl "https://raw.githubusercontent.com/alexdrone/Render/master/tools/render-watch.sh" > render-watch && mv render-watch /usr/local/bin/render-watch && chmod +x /usr/local/bin/render-watch
```

## Getting started

We're going to start with a very simple component to get familiar with **Render**'s programming model.

```swift

class SimpleCounterComponent: UIComponent<UINilState, UINilProps> {

  /// Define your component hierarchy in the *render* method.
  override func render(context: UIContextProtocol) -> UINodeProtocol {
  
    let container = UINode<UIView>(layoutSpec: containerLayoutSpec)
    let label = UINode<UILabel>(layoutSpec: labelLayoutSpec)
    
    return container.children([
      label,
    ])
  }

  private func containerLayoutSpec(_ spec: UINode<UIView>.LayoutSpec) {
    // *spec* is a proxy to the rendered view and can be used to configure the backing view for
    // your node...
    spec.set(\UIView.backgroundColor, .blue)

    // ...if necessary you can access to the view directly e.g.
    spec.view.backgroundColor = .blue

    // Render uses facebook/yoga to compute view layouts.
    spec.set(\UIView.yoga.width, spec.canvasSize.width)
  }

  private func labelLayoutSpec(_ spec: UINode<UILabel>.LayoutSpec) {
    spec.set(\UILabel.textColor, .white)
    spec.set(\UILabel.yoga.margin, 32)
    spec.set(\UILabel.text, "Number of taps: 0")
  }
}

```

