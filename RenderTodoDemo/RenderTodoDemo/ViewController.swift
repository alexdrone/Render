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
    var todoComponent = TodoListComponent()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.todoComponent.renderComponent(self.view.bounds.size)
        
        self.view.addSubview(self.todoComponent)
    }
    
    override func viewDidLayoutSubviews() {
        self.todoComponent.renderComponent(self.view.bounds.size)
        self.todoComponent.frame = self.view.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

extension ViewController: InputComponentDelegate {
    
    func inputComponentDidAddTaskWithTitle(title: String?) {
        print(title)
    }
    
}