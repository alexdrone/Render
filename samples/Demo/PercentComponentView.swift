import Foundation
import UIKit
import Render

class PercentComponentView: ComponentView<NilState> {

  required init() {
    super.init()
    // Optimization: The component doesn't have a dynamic hierarchy - this prevents the
    // reconciliation algorithm to look for differences in the component view hierarchy.
    self.defaultOptions = [.preventViewHierarchyDiff]
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("Not supported")
  }

  override func render() -> NodeType {
    return Node<UIView>() { (view, layout, size) in
      view.backgroundColor = Color.green
      layout.percent.height = 95%
      layout.percent.width = 95%;
      layout.justifyContent = .center
    }.add(child: Node<UIView>() { (view, layout, size) in
      view.backgroundColor = Color.darkerGreen
      layout.percent.height = 90%
      layout.percent.width = 90%;
    })
  }
}
