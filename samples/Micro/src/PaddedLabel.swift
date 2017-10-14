import Foundation
import RenderMicro

struct PaddedLabel {

  class Props: UINodePropsProtocol {
    var isImportant: Bool = true
    var text: String = "Untitled"
    required init() { }
  }

  class State: UIStateProtocol {
    required init() { }
  }

  class Node: UIStatefulNode<UIView, State, Props> {
    weak var wrapperView: UIView?

    init(key: String) {
      super.init(key: key, props: Props())

      let props = self.props
      set(\.backgroundColor) { props, size in props.isImportant ? .orange : .gray }
      set(\.yoga.padding, value: 50)
      set(\.yoga.alignSelf, value: .center)

      bindView(target: self, keyPath: \.wrapperView)

      let label = UIProplessNode<UILabel>()
      label.set(\.text, value: props.text)
      label.set(\.numberOfLines, value: 0)
      label.set(\.textColor) { size in props.isImportant ? .white : .black }
      label.set(\.font) { size in
        size.width > size.height ? UIFont.boldSystemFont(ofSize: 16) : UIFont.systemFont(ofSize: 13)
      }
      label.set(\.backgroundColor, value: .clear)

      set(children: [label])
    }

    override func nodeDidLayout(_ node: UINodeProtocol, view: UIView) {
      guard let wrapperView = wrapperView else { return }
    }
  }



}






