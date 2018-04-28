# Components

Components let you split the UI into independent, reusable pieces, and think about each piece in isolation.

Conceptually, components are like pure functions. They accept arbitrary inputs (called `props`) and return a tree describing what should appear on the screen.

Components can also have an associated internal state which is private and fully controlled by the component.

### Creating a component class

Every component must subclass `UIComponent<UIStateProtocol, UIPropsProtocol>`.

If you desire to have a *stateless* component you can use the special `UINilState` type as generic parameter of your class.

Similarly, if your component does not require any *props*, you can use `UINilProps` as generic parameter.

```swift
class MyStatelessProplessComponent: UIComponent<UINilState, UINilProps> {...}

class MyProps: UIProps {...}
class MyStatelessComponent: UIComponent<UINilState, MyProps> {...}

class MyState: UIState {...}
class MyStatefulComponent: UIComponent<MyState, MyProps> { }

```

### Instanting a component

Components in **Render** are always instantiated from a `UIContext`, and this is generally owned by a ViewController.

When a component is *stateless*, you can instantiate a component instance by calling `transientComponent(_:props:parent)` in `UIContext`.
Components are lightweight objects and the cost of instanting one is totally neglectable.

```swift
let component = context.transientComponent(MyStatelessComponent.self, props: MyProps(), parent: nil)
```

If your component is *stateful* it must have a **key**, and `UIContext` works like an identity map returning the same instance for the same given key - in this case the way you can obtain an instance for your *stateful* component is by calling `component(_:key:props:parent)` in `UIContext`.

```swift
let component = context.component(MyStatefulComponent.self, key: "root", props: MyProps(), parent: nil)
```

### Mouting a root component

After you have your component instance, the next step is to installing it to your view hierarchy (typically from your ViewController).
This is done through setting the component `canvasView`.

```swift
let context = UIContext()
// Create your component instance.
let component = context.component(MyStatefulComponent.self, key: "root")
// Install the component in the view hierarchy.
component.setCanvas(view: view, options: UIComponentCanvasOption.defaults())
// Render the component.
component.setNeedsRender()
```

It is strongly recommended to use `UIComponentViewController` and `UIComponentTableViewController` as base class for your ViewControllers.
This way you do not have to worry about creating/destroying the context yourself and installing the component in the ViewController view hierarchy.

Moreover `UIComponentViewController` has built-in update on orientation change, support for safe area insets and an optional [component-based navigation bar](navigation_bar.md).

```swift
class MyViewController: UIComponentViewController<MyRootComponent> {

  override func buildRootComponent() -> MyRootComponent {
    return context.component(MyRootComponent.self, key: "root")
  }
}
```

### Component rendering

The most important method of your component class is `render(context:)`.
This should return a view hierarchy description by using nodes.

```swift
class MyStatefulComponent: UIComponent<MyState, MyProps> {
	
  override func render(context: UIContext) -> UINodeProtocol {
    let container = UINode<UIView> { spec in
      spec.configure(\.yoga.width, spec.canvasSize.width)
      spec.configure(\.yoga.heigh, spec.canvasSize.height/2)
    }
    let label = UINode<UILabel> { spec
      spec.configure(\.text, "foo")
    }
    return container.children([label])
  }
}
```

Components can be reused in a very granular fashion.

```swift
class MyLabelProps: UIProps { 
  var title: String = ""
}

class MyLabelComponent: UIStatelessComponent<MyLabelProps> {

  override func render(context: UIContext) -> UINodeProtocol {
	return UINode<UILabel> { spec in spec.configure(\.text, self.props.title) }
  }
}

class MyStatefulComponent: UIComponent<MyState, MyProps> {
	
  override func render(context: UIContext) -> UINodeProtocol {
    let container = ...
   
    let label = childComponent(MyLabelProps.self, props: MyLabelProps(title: "foo")).asNode()
    return container.children([label])
  }
}
```

