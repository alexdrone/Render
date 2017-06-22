import Foundation
import UIKit
import Render

class HelloWorldComponentViewState: StateType {
  let name: String
  var count: Int = 0

  required init() {
    self.name = "Render"
  }
  init(name: String) {
    self.name = name
  }
}

class HelloWorldComponentView: ComponentView<HelloWorldComponentViewState> {

  required init() {
    super.init()
    // Optimization: The component doesn't have a dynamic hierarchy - this prevents the 
    // reconciliation algorithm to look for differences in the component view hierarchy.
    self.defaultOptions = [.preventViewHierarchyDiff]
    self.state = HelloWorldComponentViewState()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("Not supported")
  }

  override func render(size: CGSize = CGSize.undefined) -> NodeType {

    // A square image placeholder.
    let avatar =  Node<UIImageView> { (view, layout, size) in
      let radius: CGFloat = CGFloat(randomInt(16, max: 128))
      view.backgroundColor = Color.green
      (layout.height, layout.width) = (radius * 2, radius * 2)
      layout.alignSelf = .center
    }

    // The text node (a label).
    let text = Node<UILabel> { (view, layout, size) in
      view.text = "Tap Me: \(self.state.count)"
      view.textAlignment = .center
      view.textColor = Color.green
      view.font = Typography.smallBold
      layout.margin = 16
    }

    // Returns the container node (a simple UIView) wrapping the other elements.
    return Node<UIView>(key: "HelloWorld") { (view, layout, size) in
      view.backgroundColor = Color.black
      view.onTap { [weak self] _ in
        self?.setState(options: [.usePreviousBoundsAndOptions,
                                 .animated(duration: 0.2, options: [], alongside: nil)]) {
          $0.count += 1
        }
      }
      let dim =  min(size.height.maxIfZero, size.width.maxIfZero)
      (layout.height, layout.width) = (dim, dim)
      layout.justifyContent = .center
    }.add(children: [
      avatar,
      text,
    ])
  }
}
