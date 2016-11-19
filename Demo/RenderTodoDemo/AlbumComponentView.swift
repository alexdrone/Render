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

  private var featured: Bool {
    return self.album?.featured ?? false
  }

  /// Constructs the component tree.
  override func construct() -> NodeType {
    return wrapper(isFeatured: self.featured).children([
      albumCover(isFeatured: self.featured, cover: self.album?.cover).children([
        when(self.featured, defaultButton())
      ]),
      textContainer(isFeatured: self.featured).children([
        text(title: self.album?.title ?? "None", isTitle: true),
        text(title: self.album?.artist ?? "Unknown Artist", isTitle: false)
      ])
    ])
  }

  struct Metrics {
    static let bigSize: CGFloat = 320
    static let smallSize: CGFloat = 90
  }
}

fileprivate func wrapper(isFeatured: Bool) -> Node<UIView> {
  return Node<UIView>().configure { view in
    let smallSize = AlbumComponentView.Metrics.smallSize
    let bigSize = AlbumComponentView.Metrics.bigSize
    view.backgroundColor = UIColor.black
    view.useFlexbox = true
    view.layout_flexDirection = isFeatured ? .column : .row
    if isFeatured {
      view.layout_width = bigSize
      view.layout_minHeight = bigSize
      view.layout_alignSelf = .center
    } else {
      view.layout_minHeight = smallSize
      view.layout_alignSelf = .stretch
      view.layout_alignItems = .stretch
    }
  }
}

fileprivate func textContainer(isFeatured: Bool) -> Node<UIView> {
  return Node<UIView>().configure{ view in
    let bigSize = AlbumComponentView.Metrics.bigSize
    view.useFlexbox = true
    view.layout_flexDirection = .column
    view.layout_justifyContent = .center
    view.layout_flexShrink = 1
    view.layout_alignItems = .stretch
    view.layout_marginAll = 4
    view.layout_maxWidth = isFeatured ? bigSize : CGFloat(FLT_MAX)
  }
}

fileprivate func albumCover(isFeatured: Bool, cover: UIImage?) -> Node<UIImageView> {
  return Node<UIImageView>().configure { view in
    let smallSize = AlbumComponentView.Metrics.smallSize
    let bigSize = AlbumComponentView.Metrics.bigSize
    view.image = cover
    view.layer.cornerRadius = isFeatured ? 0 : smallSize/2
    view.clipsToBounds = true
    view.useFlexbox = true
    view.layout_alignSelf = .center
    view.layout_alignItems = .center
    view.layout_justifyContent = .center
    view.layout_width = isFeatured ? bigSize : smallSize
    view.layout_height = isFeatured ? bigSize : smallSize
    view.layout_marginAll = isFeatured ? 0 : 4
  }
}

fileprivate func text(title: String, isTitle: Bool) -> Node<UILabel> {
  return Node<UILabel>().configure { view in
    view.text = title
    view.font = isTitle
      ? UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightBold)
      : UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightLight)
    view.textColor = S.Color.white
    view.numberOfLines = isTitle ? 1 : 0
    view.useFlexbox = true
  }
}

fileprivate func defaultButton(title: String = "Button") -> Node<UIButton> {

  // when you construct a node with a custom initClosure setting a reuseIdentifier
  // helps the infra recycling that view.
  return Node<UIButton>(reuseIdentifier: "button", initClosure: {
    let view = UIButton()
    view.setTitleColor(S.Color.white, for: .normal)
    view.backgroundColor = S.Color.black.withAlphaComponent(0.8)
    view.titleLabel?.font = S.Typography.superSmallBold
    view.setTitle(title, for: UIControlState.normal)
    view.layer.cornerRadius = 32
    return view
  }).configure({ view in
    view.useFlexbox = true
    view.layout_width = 64
    view.layout_height = 64
    view.layout_alignSelf = .center
  })
}

