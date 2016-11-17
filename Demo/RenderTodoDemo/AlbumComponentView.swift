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
  override func construct() -> ComponentNodeType {

    // Wrapper view.
    return ComponentNode<UIView>().configure({ view in
      let size = self.referenceSize
      view.backgroundColor = UIColor.black
      view.useFlexbox = true
      view.layout_flexDirection = self.featured ? .column : .row
      view.layout_width = self.featured ? size.width/2 : size.width
      view.layout_minHeight = self.featured ? 	size.width/2 : 64

    }).children([

      // Album cover.
      ComponentNode<UIImageView>().configure({ view in
        let size = self.referenceSize
        view.image = self.album?.cover
        view.layer.cornerRadius = self.featured ? 0 : 32
        view.clipsToBounds = true
        view.useFlexbox = true
        view.layout_alignSelf = .center
        view.layout_alignItems = .center
        view.layout_justifyContent = .center
        view.layout_width = self.featured ? size.width/2 : 64
        view.layout_height = self.featured ? size.width/2 : 64
        view.layout_marginAll = self.featured ? 0 : 4
      }).children([

        // Play button.
        when(self.featured, DefaultButton())
      ]),

      // Text wrapper.
      ComponentNode<UIView>().configure({ view in
        view.useFlexbox = true
        view.layout_flexDirection = .column
        view.layout_alignSelf = .stretch
        view.layout_justifyContent = .center
        view.layout_flexShrink = 1
        view.layout_marginAll = 4

      }).children([

        // Title.
        ComponentNode<UILabel>().configure({ view in
          view.text = (self.album?.title ?? "None")
          view.font = S.Typography.mediumBold
          view.textColor = S.Color.white
          view.useFlexbox = true
        }),

        // Caption.
        ComponentNode<UILabel>().configure({ view in
          view.text = self.album?.artist ?? "Unknown Artist"
          view.font = S.Typography.extraSmallLight
          view.textColor = S.Color.white
          view.numberOfLines = 0
          view.useFlexbox = true
        })
      ])
    ])
  }
}

func DefaultButton(title: String = "Button") -> ComponentNode<UIButton> {

  // when you construct a node with a custom initClosure setting a reuseIdentifier
  // helps the infra recycling that view.
  return ComponentNode<UIButton>(reuseIdentifier: "button", initClosure: {
    let view = UIButton()
    view.useFlexbox = true
    view.layout_width = 64
    view.layout_height = 64
    view.setTitleColor(S.Color.white, for: .normal)
    view.backgroundColor = S.Color.black.withAlphaComponent(0.8)
    view.titleLabel?.font = S.Typography.superSmallBold
    view.setTitle(title, for: UIControlState.normal)
    view.layer.cornerRadius = 32
    return view
  })
}
