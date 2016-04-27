//
//  Todo.swift
//  RenderTodoDemo
//
//  Created by Alex Usbergo on 25/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import Render

class Task: ComponentStateType {
    var title: String? = ""
    var done: Bool = false
    var date: NSDate = NSDate()
    
    init(title: String? = nil) {
        self.title = title
    }
}