//
//  SingleViewController.swift
//  RenderTodoDemo
//
//  Created by Alex Usbergo on 14/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import Foundation
import Render

class SingleDemoViewController: UIViewController {

    // The item list.
    var album = Album(featured: true)
    
    /// The collection view component.
    lazy var component: AlbumComponentView = {
        let component = AlbumComponentView()
        component.state = self.album
        return component
    }()
    
    /// Called after the controller's view is loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.component)
        self.toggleFeatured()
    }
    
    /// Called to notify the view controller that its view has just laid out its subviews.
    override func viewDidLayoutSubviews() {
        self.render()
    }
    
    func render(animated: Bool = false) {
        if animated {
            UIView.animateWithDuration(0.3) {
                self.component.renderComponent()
                self.component.center = self.view.center
            }
        } else {
            self.component.renderComponent()
            self.component.center = self.view.center
        }
    }

    /// Change the component state every 2 seconds.
    func toggleFeatured() {
        delay(2) {
            self.album.featured = !self.album.featured
            self.component.state = self.album
            self.render(true)
            
            self.toggleFeatured()
        }
    }

}


func delay(delay:Double, closure:()->()) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
}