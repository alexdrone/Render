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
    
    private struct Identifiers {
        private static let TableView = "tableView"
    }
    
    /// Reference to the tableview
    var tableView: UITableView! {
        return self.root.viewWithIdentifier(Identifiers.TableView)
    }
    
    /// Constructs the component tree.
    /// - Note: Must be overriden by subclasses.
    override func construct() -> ComponentType {
        
        self.backgroundColor = UIColor.grayColor()
        
        return ComponentNode<UIView>().children([
            
            ComponentNode<InputComponent>(),
            
            ComponentNode<UITableView>(reuseIdentifier: Identifiers.TableView).configure({ tableView in
                tableView.estimatedRowHeight = 100
                tableView.rowHeight = UITableViewAutomaticDimension
                tableView.flexStyle.flex = 0.5
            })
        ])
    }
    

}
