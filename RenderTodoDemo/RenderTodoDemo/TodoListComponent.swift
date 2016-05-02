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
    
    weak var tableViewDataSource: UITableViewDataSource?
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
            
            ComponentNode<UITableView>(reuseIdentifier: Identifiers.TableView).configure({ [weak self] tableView in
                tableView.estimatedRowHeight = 100
                tableView.backgroundColor = Style.Color.LightPrimary
                tableView.rowHeight = UITableViewAutomaticDimension
                tableView.dataSource = self?.tableViewDataSource
                tableView.separatorStyle = .None
                tableView.flexStyle.flex = 0.5
            })
        ])
    }
    

}
