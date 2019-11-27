import Foundation
import UIKit
import CoreRenderObjC

// MARK: - Common Nodes

public func ViewNode(
  @ContentBuilder builder: () -> ChildrenBuilder = ChildrenBuilder.default
) -> NodeBuilder<UIView> {
  Node(UIView.self, builder: builder)
}

public func HStackNode (
  @ContentBuilder builder: () -> ChildrenBuilder = ChildrenBuilder.default
) -> NodeBuilder<UIView> {
  Node(UIView.self, builder: builder).withLayoutSpec { spec in
    guard let yoga = spec.view?.yoga else { return }
    yoga.flexDirection = .row
    yoga.justifyContent = .flexStart
    yoga.alignItems = .flexStart
    yoga.flex()
  }
}

public func VStackNode(
  @ContentBuilder builder: () -> ChildrenBuilder = ChildrenBuilder.default
) -> NodeBuilder<UIView> {
  Node(UIView.self, builder: builder).withLayoutSpec { spec in
    guard let yoga = spec.view?.yoga else { return }
    yoga.flexDirection = .column
    yoga.justifyContent = .flexStart
    yoga.alignItems = .flexStart
    yoga.flex()
  }
}

public func LabelNode(
  text: String,
  @ContentBuilder builder: () -> ChildrenBuilder = ChildrenBuilder.default
) -> NodeBuilder<UILabel> {
  Node(UILabel.self, builder: builder).withLayoutSpec { spec in
    guard let view = spec.view else { return }
    view.text = text
  }
}

public func ButtonNode(
  key: String,
  @ContentBuilder builder: () -> ChildrenBuilder = ChildrenBuilder.default
) -> NodeBuilder<UIButton> {
  Node(UIButton.self, builder: builder).withKey(key)
}

public func EmptyNode() -> NullNodeBuilder {
  return NullNodeBuilder()
}



