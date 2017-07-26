import Foundation
import Render


class AbsoluteLayoutComponent: StatelessComponentView {

  override func render() -> NodeType {

    let container = Node<UIView> { view, layout, size in
      layout.width = size.width
      layout.height = size.height
      layout.paddingTop = 64
      layout.alignItems = .center
      layout.justifyContent = .center
      view.backgroundColor = Color.black
    }

    let rect: CGSize = CGSize(width: 320, height: 320)
    return container.add(children: [
      ComponentNode(AbsoluteLayoutInnerComponent(), in: self) { component, _ in
        component.rect = rect
        component.scale = 0.9
        component.background = Color.darkerGreen
      },
      ComponentNode(AbsoluteLayoutInnerComponent(), in: self) { component, _ in
        component.rect = rect
        component.scale = 0.6
        component.background = Color.green
      },
      ComponentNode(AbsoluteLayoutInnerComponent(), in: self) { component, _ in
        component.rect = rect
        component.scale = 0.3
        component.background = Color.darkerRed
      },
    ])
  }

  /// Invoked immediately after a component is mounted.
  override func didMount() {
    alpha = 0
    UIView.animate(withDuration: 1) { [weak self] in
      self?.alpha = 1
    }
  }

}

private class AbsoluteLayoutInnerComponent: StatelessComponentView {

  var rect: CGSize = CGSize.zero
  var scale: CGFloat = 1
  var background: UIColor = Color.green

  override func render() -> NodeType {
    return Node<UIView> { view, layout, size in
      layout.width = self.rect.width * self.scale
      layout.height = self.rect.height * self.scale
      layout.justifyContent = .center

      // By setting the node layout position to absolute, this child won't follow the layout flow
      // defined by the parent node.
      layout.position = .absolute
      view.backgroundColor = self.background
    }
  }
}


class AbsoluteLayoutExampleViewController: ViewController, ComponentController {

  // Our root component.
  var component = AbsoluteLayoutComponent()

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
  }
}
