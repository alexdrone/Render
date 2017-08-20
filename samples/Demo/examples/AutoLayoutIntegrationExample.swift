import UIKit
import Render

class AutoLayoutIntegrationExample: ViewController  {

  override func loadView() {
    super.loadView()

    let avatar = AutoLayoutNestedComponentExample()
    view.addSubview(avatar)
    avatar.translatesAutoresizingMaskIntoConstraints = false

    // Render ComponentViews implement 'intrinsicContentSize'.
    // To constrain them to a specific size you have to set  use 'referenceSize' proprerty.
    // N.B: You can do this also in 'viewDidLayoutSubviews' if the size of the component is not
    // static (e.g. could depend on another view layed out with autolayout).
    avatar.referenceSize = { _ in return CGSize(width: 50, height: 50)}
    avatar.update()

    let cts = [
      avatar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      avatar.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ]
    view.addConstraints(cts)
  }
}

class AutoLayoutNestedComponentExample: StatelessComponentView {
  override public func render() -> NodeType {
    let container = Node<UIView> { view, layout, size in
      layout.width = size.width
      layout.height = size.height
      layout.padding = 10
      view.backgroundColor = Color.red
    }
    container.add(child: Node<UIView>{ view, layout, size in
      layout.percent.width = 100%
      layout.percent.height = 100%
      view.backgroundColor = Color.green
    })
    return container
  }
}

