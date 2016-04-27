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

    /// the main TODO component
    var tasks = [Task]()
    var todoComponent = TodoListComponent()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.todoComponent.configure({ component in
            component.tableViewDataSource = self
            component.inputDelegate = self
        })
                
        self.view.addSubview(self.todoComponent)
    }
    
    override func viewDidLayoutSubviews() {
        self.todoComponent.renderComponent(self.view.bounds.size)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tasks.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let id = "task"
        let cell = (tableView.dequeueReusableCellWithIdentifier(id) ?? ComponentTableViewCell(reuseIdentifier: id, component: TaskItem())) as! ComponentTableViewCell
        cell.state = self.tasks[indexPath.row]
        cell.renderComponent(CGSize(tableView.bounds.size.width))
        
        return cell
    }
}

extension ViewController: InputComponentDelegate {
    
    func inputComponentDidAddTaskWithTitle(title: String?) {
        guard let title = title where !title.isEmpty else { return }
        self.tasks.append(Task(title: title))
        self.todoComponent.tableView.reloadData()
    }
    
}