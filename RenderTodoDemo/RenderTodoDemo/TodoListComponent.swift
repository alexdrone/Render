//
//  TodoList.swift
//  RenderTodoDemo
//
//  Created by Alex Usbergo on 25/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit
import Render

class TodoListComponent: StaticComponentView {
    
    //MARK - Props
    
    var tasks = [ListComponentItemType]()
    weak var inputDelegate: InputComponentDelegate?

    //MARK: - Internal
    
    private struct Identifiers {
        private static let TableView = "tableView"
    }
    
    /// Reference to the tableview
    var tableView: UITableView! {
        return self.root.viewWithIdentifier(Identifiers.TableView)
    }
    
    /// Constructs the component tree.
    /// - Note: Must be overriden by subclasses.
    override func construct() -> ComponentNodeType {
                
        return ComponentNode<UIView>().children([
            
            ComponentNode<InputComponent>().configure({ [weak self] component in
                component.delegate = self?.inputDelegate
            }),
            
            ComponentNode<ListComponentView>().configure({ component in
                component.backgroundColor = Style.Color.Text
                component.style.flex = 0.5
                component.items = self.tasks
            })

        ])
    }
    

}
