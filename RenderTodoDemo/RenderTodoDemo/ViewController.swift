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
        registerPrototype(component: AlbumComponentView())
    }
    
    // The item list.
    var albums: [ListComponentItemType] = [ListComponentItem<AlbumComponentView, Album>]() {
        didSet {
            self.render()
        }
    }

    /// The collection view component.
    let listComponentView = ComponentCollectionView()

    /// Called after the controller's view is loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()

        // generate some fake data
        self.prepareDummyData()
        
        // configure the list component.
        self.listComponentView.configure() {
            guard let view = $0 as? ComponentCollectionView else { return }
            view.frame.size = view.parentSize
            view.backgroundColor = S.Color.black
            view.items = self.albums
        }
        
        self.view.addSubview(self.listComponentView)
    }

    /// Called to notify the view controller that its view has just laid out its subviews.
    override func viewDidLayoutSubviews() {
        self.render()
    }
    
    func render() {
        self.listComponentView.renderComponent(self.view.bounds.size)
    }
}

extension ViewController: ListComponentItemDelegate {
    
    func didSelectItem(item: ListComponentItemType, indexPath: NSIndexPath, listComponent: ComponentViewType) {
        let item = item as! ListComponentItem<AlbumComponentView, Album>
        self.albums = albums.map({ $0 as! ListComponentItem<AlbumComponentView, Album> }).filter({ $0.state != item.state }).map({ $0 as ListComponentItemType })
    }
}

extension ViewController {
    
    //creates some dummy models.
    func prepareDummyData() {
        for idx in 0..<10 {
            let item = ListComponentItem<AlbumComponentView, Album>(state: Album(featured: idx < 4))
            item.delegate = self
            self.albums.append(item)
        }
    }
    
}
