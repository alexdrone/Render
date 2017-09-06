import UIKit
import Render

class AutoLayoutIntegrationExample: ViewController  {

  override func loadView() {
    super.loadView()

    let avatar = ComponentAnchorView(component: AutoLayoutNestedComponentExample())
    view.addSubview(avatar)

    let cts = [
      avatar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      avatar.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 50),
      avatar.heightAnchor.constraint(equalToConstant: 50),
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

