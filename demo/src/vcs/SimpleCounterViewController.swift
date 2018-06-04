import UIKit
import RenderNeutrino

// MARK: - SimpleCounterViewController1

class SimpleCounterViewController1: UIComponentViewController<SimpleCounterComponent1> {

  override func viewDidLoad() {
    styleNavigationBarComponent(title: "Getting Started I")
    super.viewDidLoad()
  }

  override func buildRootComponent() -> SimpleCounterComponent1 {
    // We can create a new component using the ViewController's context.
    return context.transientComponent(SimpleCounterComponent1.self)
  }
}

// MARK: - SimpleCounterViewController2

class SimpleCounterViewController2: UIComponentViewController<SimpleCounterComponent2> {

  override func viewDidLoad() {
    styleNavigationBarComponent(title: "Getting Started II")
    super.viewDidLoad()
  }

  override func buildRootComponent() -> SimpleCounterComponent2 {
    // The component is now stateful, and we cannot construct it by calling *transientComponent*.
    // Also for every stateful component we need to specify a key.
    // If no key is specified the framework infers one from the component name but this will not
    // work if you have 2 components of the same type in the same context.
    return context.component(SimpleCounterComponent2.self, key: "counter")
  }
}

// MARK: - SimpleCounterViewController3

class SimpleCounterViewController3: UIComponentViewController<SimpleCounterComponent3> {

  override func viewDidLoad() {
    styleNavigationBarComponent(title: "Getting Started III")
    super.viewDidLoad()
  }

  override func buildRootComponent() -> SimpleCounterComponent3 {
    let component = context.component(SimpleCounterComponent3.self)
    // Component props are used to pass data from your model to your component.
    component.props.format = "How heavy is your neutrino? %d eV/c2."
    return component
  }
}

// MARK: - SimpleCounterViewController4

class SimpleCounterViewController4: UIComponentViewController<SimpleCounterComponent4> {

  override func viewDidLoad() {
    styleNavigationBarComponent(title: "Getting Started IV")
    super.viewDidLoad()
  }

  override func buildRootComponent() -> SimpleCounterComponent4 {
    return context.component(SimpleCounterComponent4.self)
  }
}

// MARK: - SimpleCounterViewController5

class SimpleCounterViewController5: UIComponentViewController<SimpleCounterComponent5> {

  override func viewDidLoad() {
    styleNavigationBarComponent(title: "Getting Started V")
    super.viewDidLoad()
  }

  override func buildRootComponent() -> SimpleCounterComponent5 {
    return context.component(SimpleCounterComponent5.self)
  }
}


