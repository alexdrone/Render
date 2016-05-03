//
//  TaskItemComponent.swift
//  RenderTodoDemo
//
//  Created by Alex Usbergo on 27/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit
import Render

class TaskItemComponent: StaticComponentView {

    private var task: Task! {
        return (self.state as? Task) ?? Task()
    }
    
    /// Constructs the component tree.
    /// - Note: Must be overriden by subclasses.
    override func construct() -> ComponentNodeType {
        
        return ComponentNode<UIView>().configure({ (view) in
            view.backgroundColor = Style.Color.LightPrimary
            view.style.alignItems = .FlexStart
            view.style.alignSelf = .FlexStart
            view.style.justifyContent = .FlexStart
            view.style.dimensions.width = ~self.parentSize.width/2 - Style.Metrics.DefaultMargin.left - Style.Metrics.DefaultMargin.right
            view.style.dimensions.height = view.style.dimensions.width - Style.Metrics.DefaultMargin.top - Style.Metrics.DefaultMargin.bottom
            view.style.margin = Style.Metrics.DefaultMargin

        }).children([
            
            ComponentNode<UILabel>().configure({ label in
                label.text = self.task.title
                label.textColor = Style.Color.PrimaryText
                label.font = Style.Typography.MediumBold
                label.backgroundColor = Style.Color.Primary
                label.style.alignSelf = .FlexStart
                label.style.flex = Flex
                label.style.justifyContent = .FlexStart

            }),
            
        ])
    }
    
    
}
