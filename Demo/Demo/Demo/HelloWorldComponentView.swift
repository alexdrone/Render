import Foundation
import UIKit
import Render

struct HelloWorldState: StateType {
  let name: String
}

class HelloWorldComponentView: ComponentView<HelloWorldState> {

  override init() {
    super.init()
    self.defaultOptions = [.preventViewHierarchyDiff]
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("Not supported")
  }

  override func construct(state: HelloWorldState?, size: CGSize = CGSize.undefined) -> NodeType {
    func avatar() -> NodeType {
      return Node<UIImageView> { (view, layout, size) in
        let radius: CGFloat = 64
        view.backgroundColor = Color.green
        view.layer.cornerRadius = radius
        layout.height = radius * 2
        layout.width = radius * 2
        layout.alignSelf = .center
      }
    }
    func text(text: String?) -> NodeType {
      return Node<UILabel> { (view, layout, size) in
        view.text = "Hello \(text ?? "stranger")"
        view.textAlignment = .center
        view.textColor = Color.green
        view.font = Typography.smallBold
        layout.margin = 16
      }
    }
    func container() -> NodeType {
      return Node<UIImageView> { (view, layout, size) in
        view.backgroundColor = Color.black
        layout.width = min(size.width, size.height)
        layout.height = layout.width
        layout.justifyContent = .center
      }
    }

    return container().addChildren([
      avatar(),
      text(text: state?.name)
    ])
  }
}
