//
//  ViewController.swift
//  RenderTodoDemo
//
//  Created by Alex Usbergo on 25/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit
import Render

class ViewController: UIViewController {
    
    override class func initialize() {
        ListComponentView.registerPrototype(String(TaskItemComponent.self), component: TaskItemComponent())
    }

    /// the main TODO component
    var tasks: [ListComponentItemType] = [ListComponentItem<TaskItemComponent, Task>]()
    var todoComponent = TodoListComponent()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.todoComponent.configure({
            guard let component = $0 as? TodoListComponent else { return }
            component.inputDelegate = self
            component.tasks = self.tasks
        })
        
        self.view.addSubview(self.todoComponent)
    }
    
    override func viewDidLayoutSubviews() {
        self.render()
    }
    
    func render() {
        self.todoComponent.renderComponent(self.view.bounds.size)
    }
}

extension ViewController: InputComponentDelegate, ListComponentItemDelegate {
    
    func inputComponentDidAddTaskWithTitle(title: String?) {
        guard let title = title where !title.isEmpty else { return }
        let item = ListComponentItem<TaskItemComponent, Task>(state: Task(title: title))
        item.delegate = self
        self.tasks.append(item)
        self.render()
    }
    
    func didSelectItem(item: ListComponentItemType, indexPath: NSIndexPath, listComponent: ListComponentView) {
        let selectedItem = item as!  ListComponentItem<TaskItemComponent, Task>
        self.tasks = self.tasks.map({ $0 as! ListComponentItem<TaskItemComponent, Task> }).filter({ $0.state.title != selectedItem.state.title }).map({ $0 as ListComponentItemType })
        self.render()
    }
    
}