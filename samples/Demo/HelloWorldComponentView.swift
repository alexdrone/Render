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

  enum Key: String {
    case avatar
    case container
    case circle
    case text
  }

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
    let avatar = Node<UIImageView>(key: Key.avatar.rawValue) { (view, layout, size) in
      let radius: CGFloat = CGFloat(randomInt(16, max: 128))
      view.backgroundColor = Color.green
      view.cornerRadius = radius
      (layout.height, layout.width) = (radius * 2, radius * 2)
      layout.alignSelf = .center
    }

    // The text node (a label).
    let text = Node<UILabel>(key: Key.text.rawValue) { (view, layout, size) in
      view.text = "Tap Me: \(self.state.count)"
      view.textAlignment = .center
      view.textColor = Color.green
      view.font = Typography.smallBold
      layout.margin = 16
    }

    // You can opt-out the view from the flexbox layout engine by
    // setting 'yoga.isIncludedInLayout' to 'false'.
    // Remember to lay out the view manually in the 'didUpdate' method.
    let circle = Node<UILabel>(key: Key.circle.rawValue) {  (view, layout, size) in
      view.yoga.isIncludedInLayout = false
      view.backgroundColor = Color.red
      view.clipsToBounds = true
    }

    // Returns the container node (a simple UIView) wrapping the other elements.
    return Node<UIView>(key: Key.container.rawValue) { (view, layout, size) in
      view.backgroundColor = Color.black
      view.onTap { [weak self] _ in
        self?.setState(options: [.usePreviousBoundsAndOptions,
                                 .animated(duration: 0.5, options: [], alongside: nil)]) {
          $0.count += 1
        }
      }
      let dim =  min(size.height.maxIfZero, size.width.maxIfZero)
      (layout.height, layout.width) = (dim, dim)
      layout.justifyContent = .center
    }.add(children: [
      avatar,
      text,
      circle
    ])
  }

  override func onLayout(duration: TimeInterval) {
    guard let circle = views(key: Key.circle.rawValue).first,
          let avatar = views(key: Key.avatar.rawValue).first else  {
      return
    }
    let size: CGFloat = avatar.bounds.size.width/2
    circle.frame.size =  CGSize(width: size, height: size)
    circle.center = avatar.center
    circle.cornerRadius = size/2
    circle.animateCornerRadiusInHierarchyIfNecessary(duration: duration)
  }
}
