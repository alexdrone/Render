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

// This will just improve the performance in list diffs.
extension Video: ComponentStateTypeUniquing {
    var stateUniqueIdentifier: String {
        return self.id
    }
}

class VideoComponentView: StaticComponentView {
    
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
                    view.style.alignSelf = .Stretch
                    view.style.justifyContent = .Center
                    view.style.flexDirection = .Row
                    
                }).children([
                    DefaultButton().configure({ view in
                        view.setTitle("FOO", forState: .Normal)
                    }),
                    DefaultButton().configure({ view in
                        view.setTitle("BAR", forState: .Normal)
                    }),
                    DefaultButton().configure({ view in
                        view.setTitle("BAZ", forState: .Normal)
                    })
                ])
            ])
            
        ])
    }
}


