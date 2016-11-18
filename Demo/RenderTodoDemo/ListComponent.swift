//
//  ListComponent.swift
//  RenderTodoDemo
//
//  Created by Alex Usbergo on 11/18/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit
import Render

struct ListComponentState: ComponentStateType {
  let albums: [Album]
}

class ListComponentView: ComponentView {

  var list: ListComponentState? {
    return self.state as? ListComponentState
  }

  override func construct() -> NodeType {

    let root = Node<UIScrollView>().configure({ view in
      view.useFlexbox = true
      view.layout_flexGrow = 1
      view.layout_alignSelf = .stretch
      view.layout_alignItems = .center
      view.backgroundColor = UIColor.black
    })

    guard let list = self.list, !list.albums.isEmpty else {
      return root
    }

    for album in list.albums {
      root.add(child: Node<AlbumComponentView>().configure({ view in
        view.useFlexbox = true
        view.state = album
        view.layout_flexGrow = 1
        view.layout_alignSelf = .stretch
      }))
    }

    return root
  }

}
