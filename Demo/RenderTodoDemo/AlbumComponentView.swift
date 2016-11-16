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

    // Wrapper view.
    return ComponentNode<UIView>().configure({ view in
      let size = self.referenceSize
      view.backgroundColor = UIColor.black
      view.css_usesFlexbox = true
      view.css_flexDirection = self.featured ? CSSFlexDirectionColumn : CSSFlexDirectionRow
      view.css_width = self.featured ? size.width/2 : size.width
      view.css_minHeight = self.featured ? 	size.width/2 : 64

    }).children([

      // Album cover.
      ComponentNode<UIImageView>().configure({ view in
        let size = self.referenceSize
        view.image = self.album?.cover
        view.css_usesFlexbox = true
        view.css_alignSelf = CSSAlignCenter
        view.css_alignItems = CSSAlignCenter
        view.css_justifyContent = CSSJustifyCenter
        view.css_width = self.featured ? size.width/2 : 64
        view.css_height = self.featured ? size.width/2 : 64
        view.css_setMargin(4, for: CSSEdgeLeft)
        view.css_setMargin(4, for: CSSEdgeRight)
      }).children([

        // Play button.
        when(self.featured, DefaultButton())
      ]),

      // Text wrapper.
      ComponentNode<UIView>().configure({ view in
        view.css_usesFlexbox = true
        view.css_flexDirection = CSSFlexDirectionColumn
        view.css_alignSelf = CSSAlignStretch
        view.css_justifyContent = CSSJustifyCenter
        view.css_flexShrink = 1
        view.css_setMargin(4, for: CSSEdgeTop)
        view.css_setMargin(4, for: CSSEdgeLeft)
        view.css_setMargin(4, for: CSSEdgeRight)
        view.css_setMargin(4, for: CSSEdgeBottom)

      }).children([

        // Title.
        ComponentNode<UILabel>().configure({ view in
          view.text = (self.album?.title ?? "None") + "_random\(randomInt(0, max: 10))"
          view.font = S.Typography.mediumBold
          view.textColor =  S.Color.white
          view.css_usesFlexbox = true
        }),

        // Caption.
        ComponentNode<UILabel>().configure({ view in
          view.text = self.album?.artist ?? "Unknown Artist"
          view.font = S.Typography.extraSmallLight
          view.textColor = UIColor.red
          view.numberOfLines = 0
          view.backgroundColor = UIColor.gray.withAlphaComponent(0.67)
          view.css_usesFlexbox = true
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
    view.css_usesFlexbox = true
    view.css_width = 64
    view.css_height = 64
    view.setTitleColor(S.Color.white, for: .normal)
    view.backgroundColor = S.Color.black.withAlphaComponent(0.8)
    view.titleLabel?.font = S.Typography.superSmallBold
    view.setTitle(title, for: UIControlState.normal)
    view.layer.cornerRadius = 32
    return view
  })
}
