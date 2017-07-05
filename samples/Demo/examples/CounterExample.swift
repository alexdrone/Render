import UIKit
import Render

// A simple component state that keeps track of the number of times the user tapped on the view.
struct CounterComponentViewState: StateType {
  var numberOfTaps: Int = 0
}

// In this example we introduce a stateful component.
// What's the exact difference between props and state?
// PROPS
// props (short for properties) are a Component's configuration, its options if you may.
// They are received from above and immutable as far as the Component receiving them is concerned.
// A Component cannot change its props, but it is responsible for putting together the props
// of its child Components.
// STATE
// The state starts with a default value when a Component mounts and then suffers from mutations
// in time (mostly generated from user events). It's a serializable* representation of one point in
// time—a snapshot.
// A Component manages its own state *internally*, but—besides setting an initial state—has no
// business fiddling with the state of its children. You could say the state is private.
class CounterComponentView: ComponentView<CounterComponentViewState> {

  required init() {
    super.init()
    // Optimization: The component doesn't have a dynamic hierarchy - this prevents the
    // reconciliation algorithm to look for differences in the component view hierarchy.
    defaultOptions = [.preventViewHierarchyDiff]
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func render() -> NodeType {
    let containter = Node<UIView> { view, layout, size in
      view.backgroundColor = Color.red
      view.transform = CGAffineTransform.identity
      view.onTap { [weak self] _ in
        // Render gives you a reference to every view you're building in the render method.
        // In this way is possibile to implement any sort of custom animation (even gesture
        // based ones).
        self?.popView(view: view) {
          self?.setState { state in state.numberOfTaps += 1 }
        }
      }
      view.cornerRadius = 32
      layout.width = 64
      layout.height = layout.width
      layout.justifyContent = .center
      layout.alignSelf = .center
      layout.margin = 16
    }
    let label = Node<UILabel> { view, layout, size in
      view.font = Typography.mediumBold
      view.textColor = Color.white
      // The label renders from the state.
      view.text = "\(self.state.numberOfTaps)"
      layout.alignSelf = .center
    }
    return containter.add(child: label)
  }

  private func popView(view: UIView, completion: @escaping () -> ()) {
    func animateIn() {
      view.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
      view.backgroundColor = Color.darkerRed
    }
    func animateOut(finished: Bool) {
      view.transform = CGAffineTransform.identity
      completion()
    }
    UIView.animate(withDuration: 0.3, animations: animateIn, completion: animateOut(finished:))
  }
}

class CounterExampleViewController: ViewController, ComponentController {

  // Our root component.
  var component = CounterComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Adds the component to the view hierarchy.
    addComponentToViewControllerHierarchy()
  }

  // Whenever the view controller changes bounds we want to re-render the component.
  override func viewDidLayoutSubviews() {
    renderComponent()
  }

  func configureComponentProps() {
    // No props to configure
  }
  
}
