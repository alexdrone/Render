import UIKit
import Render

struct Fragments {

  static func paddedLabel(text: String?) -> NodeType {
    // A box around the label with a little margin.
    return Node<UIView>() { (view, layout, size) in
      layout.margin = 4
      layout.padding = 4
      layout.alignSelf = .flexStart
      view.backgroundColor = Color.green
      }.add(children: [
        // The actual label.
        Node<UILabel>() { (view, layout, size) in
          view.text = text ?? "N/A"
          view.numberOfLines = 0
          view.textColor = Color.darkerGreen
          view.font = Typography.small
        }
    ])
  }

  static func subtitleLabel(text: String?) -> NodeType {
    return Node<UILabel>() { (view, layout, size) in
      view.text = text
      view.numberOfLines = 0
      view.textColor = Color.green
      view.font = Typography.smallLight
      layout.margin = 4
    }
  }

  static func avatar() -> NodeType {
    // A squared item that works as avatar in the layout.
    // NB: The image could be passed in the state.
    return Node<UIImageView> { (view, layout, size) in
      view.backgroundColor = Color.green
      layout.margin = 4
      let s = size.width/6.66
      layout.height = s
      layout.width = s
    }
  }

  static func button() -> NodeType {
    // The red button at the bottom right corner of the component.
    return Node<UIView>() { (view, layout, size) in
      layout.alignSelf = .flexEnd
      layout.height = 32
      layout.width = 72
      layout.margin = 8
      view.backgroundColor = Color.red
    }
  }
}
