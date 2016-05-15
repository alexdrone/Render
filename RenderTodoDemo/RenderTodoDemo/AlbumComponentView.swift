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

// This will just improve the performance in list diffs.
extension Album: ComponentStateTypeUniquing {
    var stateUniqueIdentifier: String {
        return self.id
    }
}

class AlbumComponentView: StaticComponentView {
    
    // If the component is used as list item it should be registered
    // as prototype for the infra.
    override class func initialize() {
        registerPrototype(component: AlbumComponentView())
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
        
        return ComponentNode<UIView>().configure({ view in
            
            view.style.flexDirection = self.featured ? .Column : .Row
            view.backgroundColor = S.Color.black
            view.style.dimensions.width = self.featured ? ~self.parentSize.width/2 : ~self.parentSize.width
            view.style.dimensions.height = self.featured ? Undefined : 64

        }).children([
            
            ComponentNode<UIImageView>().configure({ view in
                view.image = self.album?.cover
                view.style.alignSelf = .Center
                view.style.dimensions.width = self.featured ? ~self.parentSize.width/2 : 48
                view.style.dimensions.height = self.featured ? view.style.dimensions.width : 48
            }),
            
            ComponentNode<UIView>().configure({ view in
                view.style.flexDirection = .Column
                view.style.margin = S.Album.defaultInsets
                view.style.alignSelf = .Center
                
            }).children([
                
                ComponentNode<UILabel>().configure({ view in
                    view.style.margin = S.Album.defaultInsets
                    view.text = self.album?.title ?? "None"
                    view.font = S.Typography.mediumBold
                    view.textColor = S.Color.white
                }),
                
                ComponentNode<UILabel>().configure({ view in
                    view.style.margin = S.Album.defaultInsets
                    view.text = self.album?.artist ?? "Uknown Artist"
                    view.font = S.Typography.extraSmallLight
                    view.textColor = S.Color.white
                })
            ]),
            
            
        ])
    }
    
}