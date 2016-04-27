//
//  Input.swift
//  RenderTodoDemo
//
//  Created by Alex Usbergo on 25/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit
import Render

protocol InputComponentDelegate: class {
    func inputComponentDidAddTaskWithTitle(title: String?)
}

class InputComponent: StaticComponentView {
    
    private struct Identifiers {
        private static let InputField = "inputField"
    }
    
    private var inputField: UITextField! {
        return self.root.viewWithIdentifier(Identifiers.InputField)
    }
    
    weak var delegate: InputComponentDelegate?
 
    /// Constructs the component tree.
    /// - Note: Must be overriden by subclasses.
    override func construct() -> ComponentType {
        
        return ComponentNode<UIView>().configure({ (view) in
            view.backgroundColor = Style.Color.DarkPrimary
            view.style.minDimensions.height = 160
            view.style.alignSelf = .Stretch
            view.style.flexDirection = .Row
            view.style.alignItems = .Center
            
        }).children([
        
            ComponentNode<UITextField>(reuseIdentifier: Identifiers.InputField).configure({ field in
                field.placeholder = "Task title"
                field.backgroundColor = Style.Color.Divider
                field.textColor = Style.Color.PrimaryText
                field.textAlignment = .Center
                field.style.dimensions.height = 48
                field.style.flex = Flex
                field.style.margin = Style.Metrics.DefaultMargin
                field.style.margin.right = 0
                field.style.margin.end = 0
            }),
            
            ComponentNode<UIButton>().configure({ button in
                button.setTitle("Add", forState: .Normal)
                button.setTitleColor(Style.Color.Text, forState: .Normal)
                button.backgroundColor = Style.Color.Accent
                button.style.dimensions.height = 48
                button.style.dimensions.width = 96
                button.style.margin = Style.Metrics.DefaultMargin
                button.style.margin.left = 0
                button.style.margin.start = 0
                button.addTarget(self, action: #selector(InputComponent.didPressAddButton(_:)), forControlEvents: .TouchUpInside)
            })
        ])
    }
    
    dynamic func didPressAddButton(sender: UIButton) {
        self.delegate?.inputComponentDidAddTaskWithTitle(self.inputField.text)
        self.inputField.text = nil
    }
    
    
}
