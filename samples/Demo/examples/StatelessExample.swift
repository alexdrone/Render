import UIKit
import Render

// The simplest way to define a component is to write a pure Swift function.
// The arguments of the function are analogous to the props in React world.
// (https://facebook.github.io/react/docs/components-and-props.html)
// Functions are great to have very fine grain code reuse.
func PaddedLabel(text: String,
                 background: UIColor = Color.green,
                 foreground: UIColor = Color.black) -> NodeType {
  // A box around the label with a little margin.
  // ReuseIdentifiers in nodes helps the infra to pick the best view to recycle during
  // the reconciliation phase.
  return Node<UIView>(reuseIdentifier: "paddedLabel") { (view, layout, size) in
    layout.margin = 4
    layout.padding = 6
    layout.alignSelf = .flexStart
    view.backgroundColor = background
    view.cornerRadius = 4
    }.add(children: [
      // The actual label.
      Node<UILabel> { view, layout, size in
        view.text = text
        view.numberOfLines = 0
        view.textColor = foreground
        view.font = Typography.smallLight
      }
    ])
}

// Another way to have a simple purely functional way to define a component is through a
// StatelessComponent subclass.
// In this case the 'props' will simply be the object properties exposed.
class HelloComponentView: StatelessComponentView {

  // Render is pretty flexible but it has a single strict rule:
  // All components must act like pure functions with respect to their props (and their state).
  var text: String = ""

  required init() {
    super.init()
    // Optimization: The component doesn't have a dynamic hierarchy - this prevents the
    // reconciliation algorithm to look for differences in the component view hierarchy.
    defaultOptions = [.preventViewHierarchyDiff]
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // This is the function that generate a new description of the component, every time
  // the 'update' or 'setState' function is called.
  override func render() -> NodeType {
    return Node<UIView> { view, layout, size in
      view.backgroundColor = Color.black
      layout.flexDirection = .row
    }.add(children: [
      // Components can refer to other components in their output.
      // This lets us use the same component abstraction for any level of detail.
      // A button, a form, a dialog, a screen: in Render all those are commonly
      // expressed as components.
      PaddedLabel(text: "Hello", background: Color.red, foreground: Color.white),
      PaddedLabel(text: text)
    ])
  }
}

// 'ComponentController' is a useful UIViewController protocol to wrap a root component in a
// view controller.
class StatelessComponentExampleViewController: ViewController, ComponentController {

  // Our root component.
  var component = HelloComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Adds the component to the view hierarchy.
    addComponentToViewControllerHierarchy()
  }

  // Whenever the view controller changes bounds we want to re-render the component.
  override func viewDidLayoutSubviews() {
    renderComponent()
  }

  // This is invoked before 'renderComponent'.
  func configureComponentProps() {
    component.text = "Stranger"
  }
}
