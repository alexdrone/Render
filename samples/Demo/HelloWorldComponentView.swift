import Foundation
import UIKit
import Render

struct HelloWorldState: StateType {
  let name: String
}

class HelloWorldComponentView: ComponentView<HelloWorldState> {
  required init() {
    super.init()
    // Optimization: The component doesn't have a dynamic hierarchy - this prevents the 
    // reconciliation algorithm to look for differences in the component view hierarchy.
    self.defaultOptions = [.preventViewHierarchyDiff]
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("Not supported")
  }

  override func construct(state: HelloWorldState?, size: CGSize = CGSize.undefined) -> NodeType {

    // A square image placeholder.
    let avatar =  Node<UIImageView> { (view, layout, size) in
      let radius: CGFloat = CGFloat(randomInt(16, max: 128))
      view.backgroundColor = Color.green
      (layout.height, layout.width) = (radius * 2, radius * 2)
      layout.alignSelf = .center
    }

    // The text node (a label).
    let text = Node<UILabel> { (view, layout, size) in
      view.text = "Hello \(state?.name ?? "stranger")"
      view.textAlignment = .center
      view.textColor = Color.green
      view.font = Typography.smallBold
      layout.margin = 16
    }

    // Returns the container node (a simple UIView) wrapping the other elements.
    return Node<UIView>(identifier: "HelloWorld") { (view, layout, size) in
      view.backgroundColor = Color.black
      let dim =  min(size.height.maxIfZero, size.width.maxIfZero)
      (layout.height, layout.width) = (dim, dim)
      layout.justifyContent = .center
    }.add(children: [
      avatar,
      text,
    ])
  }
}
