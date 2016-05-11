//
//  VideoComponentView.swift
//  RenderTodoDemo
//
//  Created by Alex Usbergo on 11/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit
import Render

// the model is marked as component state.
extension Video: ComponentStateType { }

class VideoComponentView: ComponentView {
    
    // If the component is used as list item it should be registered
    // as prototype for the infra.
    override class func initialize() {
        registerPrototype(component: VideoComponentView())
    }
    
    /// The component state.
    var video: Video? {
        return self.state as? Video
    }
    
    /// Constructs the component tree.
    override func construct() -> ComponentNodeType {
        
        return ComponentNode<UIView>().configure({ view in
            view.style.flexDirection = .Column
            view.backgroundColor = S.Color.black
            view.style.dimensions.width =  ~self.parentSize.width
            
        }).children([
            
            ComponentNode<UIImageView>().configure({ view in
                view.image = self.video?.cover
                view.style.alignItems = .Center
                view.style.dimensions.width = ~self.parentSize.width
                view.style.dimensions.height = (~self.parentSize.width * 9)/16

            }).children([
                
                ComponentNode<UIView>().configure({ view in
                    view.style.flex = Flex.Max
                }),
                ComponentNode<UIButton>().configure({ view in
                    view.style.dimensions = (64, 64)
                    view.style.alignSelf = .Center
                    view.style.justifyContent = .Center
                    view.setTitle("REMOVE", forState: .Normal)
                    view.setTitleColor(S.Color.white, forState: .Normal)
                    view.titleLabel?.font = S.Typography.extraSmallLight
                }),
                ComponentNode<UIView>().configure({ view in
                    view.style.flex = Flex.Max
                })
            ])
            
        ])
    }
    
    
}