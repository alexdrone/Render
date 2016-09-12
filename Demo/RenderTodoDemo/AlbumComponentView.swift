//
//  AlbumComponentView.swift
//  RenderTodoDemo
//
//  Created by Alex Usbergo on 03/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit
import Render

// The model is marked as component state.
extension Album: ComponentStateType { }

class AlbumComponentView: ComponentView {

  // If the component is used as list item it should be registered
  // as prototype for the infra.
  override class func initialize() {
    ComponentPrototypes.registerComponentPrototype(component: AlbumComponentView())
  }

  /// The component state.
  var album: Album? {
    return self.state as? Album
  }

  var featured: Bool {
    return self.album?.featured ?? false
  }

  /// Constructs the component tree.
  override func construct() -> ComponentNodeType {
    let size = self.referenceSize
    return ComponentNode<UIView>(props: [
      #keyPath(flexDirection): self.featured
                               ? Directive.FlexDirection.column.rawValue
                               : Directive.FlexDirection.row.rawValue,
      #keyPath(backgroundColor): S.Color.black,
      #keyPath(flexDimensions): self.featured
                                ? CGSize(width: size.width/2, height: CGFloat(Undefined))
                                : CGSize(width: size.width, height: 64)]) .children([

        // image view.
        ComponentNode<UIImageView>(props: [
          #keyPath(UIImageView.image): self.album?.cover,
          #keyPath(flexAlignSelf): Directive.Align.center.rawValue,
          #keyPath(flexDimensions): self.featured
                                    ? CGSize(width: size.width/2, height: size.width/2)
                                    : CGSize(width: 48, height: 48)]).children([

            // When the items is featured, there's a node with a button.
            when(self.featured, ComponentNode<UIView>(props: [
              #keyPath(flexGrow): Flex.Max,
              #keyPath(flexAlignSelf): Directive.Align.stretch.rawValue,
              #keyPath(flexJustifyContent): Directive.Justify.center.rawValue]).children([
                DefaultButton().configure { $0.setTitle("PLAY", for: .normal)}
              ]))
        ]),

        // Text wrapper.
        ComponentNode<UIView>(props: [
          #keyPath(flexDirection): Directive.FlexDirection.column.rawValue,
          #keyPath(flexMargin): UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4),
          #keyPath(flexAlignSelf): Directive.Align.center.rawValue,]).children([

          // Title.
          ComponentNode<UILabel>(props: [
            #keyPath(flexMargin): UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4),
            #keyPath(UILabel.text): self.album?.title ?? "None",
            #keyPath(UILabel.font): S.Typography.mediumBold,
            #keyPath(UILabel.textColor): S.Color.white]),

          // Subitle.
          ComponentNode<UILabel>(props: [
            #keyPath(flexMargin): UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4),
            #keyPath(UILabel.text): self.album?.artist ?? "Unknown artist",
            #keyPath(UILabel.font): S.Typography.extraSmallLight,
            #keyPath(UILabel.textColor): S.Color.white]),
        ])
    ])

  }
}


func DefaultButton() -> ComponentNode<UIButton> {

  // when you construct a node with a custom initClosure setting a reuseIdentifier
  // helps the infra recycling that view.
  return ComponentNode<UIButton>(reuseIdentifier: "DefaultButton", initClosure: {
    let view = UIButton()
    view.style.dimensions = (64, 64)
    view.style.alignSelf = .center
    view.style.justifyContent = .center
    view.style.margin = S.Album.defaultInsets
    view.setTitleColor(S.Color.white, for: .normal)
    view.backgroundColor = S.Color.black.withAlphaComponent(0.8)
    view.titleLabel?.font = S.Typography.superSmallBold
    view.layer.cornerRadius = 32
    return view
  })
}
