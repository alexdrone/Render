import Foundation
import UIKit
import Render

class DotComponentView: ComponentView<NilState> {

  // Components can expose props.
  var numberOfDots: Int = 0

  override func render() -> NodeType {
    // A simple green circle.
    func dot() -> NodeType {
      return Node<UIView> { (view, layout, _) in
        view.backgroundColor = Color.green
        view.layer.cornerRadius = 8
        layout.margin = 2
        layout.height = 16
        layout.width = 16
      }
    }
    let n = self.numberOfDots
    return Node<UIView>(key: "Dot") { (_, layout, _) in
      layout.margin = 4
      layout.flexDirection = .row
      layout.flexWrap = .wrap
    }.add(children: (0..<n).map { _ in dot() })
  }

}
