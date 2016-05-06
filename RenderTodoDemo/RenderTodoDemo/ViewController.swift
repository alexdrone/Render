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
        ListComponentView.registerPrototype(component: AlbumComponentView())
    }
    
    var albums: [ListComponentItemType] = [ListComponentItem<AlbumComponentView, Album>]()
    var listView = ListComponentView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //creates some dummy models
        for idx in 0..<100 {
            let item = ListComponentItem<AlbumComponentView, Album>(state: Album(featured: idx < 4))
            item.delegate = self
            self.albums.append(item)
        }
        
        self.listView.items = self.albums
        self.listView.backgroundColor = S.Color.black
        
        self.view.addSubview(self.listView)
    }
    
    override func viewDidLayoutSubviews() {
        self.listView.frame = self.view.bounds
        self.render()
    }
    
    func removeItem(item: ListComponentItem<AlbumComponentView, Album>) {
        self.albums = albums.map({ $0 as! ListComponentItem<AlbumComponentView, Album> }).filter({ $0.state != item.state }).map({ $0 as ListComponentItemType })
        self.listView.items = self.albums
    }
    
    func render() {
        self.listView.renderComponent(self.view.bounds.size)
    }
}

extension ViewController: ListComponentItemDelegate {
    
    func didSelectItem(item: ListComponentItemType, indexPath: NSIndexPath, listComponent: ListComponentView) {

        let item = item as! ListComponentItem<AlbumComponentView, Album>

        self.albums = albums.map({ $0 as! ListComponentItem<AlbumComponentView, Album> }).filter({ $0.state != item.state }).map({ $0 as ListComponentItemType })
        self.listView.items = albums
        
        //item.state.featured = !item.state.featured
        //self.listView.renderComponentAtIndexPath(indexPath)
    }
}
