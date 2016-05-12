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
    
    // The item list.
    var albums: [ListComponentItemType] = [ListComponentItem<AlbumComponentView, Album>]() {
        didSet {
            self.listComponentView.renderComponent(self.view.bounds.size)
        }
    }
    
    /// The collection view component.
    lazy var listComponentView: ComponentCollectionView = {
        return ComponentCollectionView()
    }()
    
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
        self.listComponentView.renderComponent(self.view.bounds.size)
    }
}

extension ViewController: ListComponentItemDelegate {
    
    func didSelectItem(item: ListComponentItemType, indexPath: NSIndexPath, listComponent: ComponentViewType) {
        
        // collapse the item if expanded
        if let albumItem = item as? ListComponentItem<AlbumComponentView, Album> where albumItem.state.featured {
            albumItem.state.featured = false
            listComponentView.renderComponentAtIndexPath(indexPath)
            return
        }
        
        //we want to remove an album
        if let albumItem = item as? ListComponentItem<AlbumComponentView, Album> {
            self.albums = self.albums.filter({
                guard let otherAlbum = $0 as? ListComponentItem<AlbumComponentView, Album> else { return true }
                return otherAlbum.state != albumItem.state
            })
            
        //we want to remove a video
        } else if let videoItem = item as? ListComponentItem<VideoComponentView, Video> {
            self.albums = self.albums.filter({
                guard let otherVideo = $0 as? ListComponentItem<VideoComponentView, Video> else { return true }
                return otherVideo.state != videoItem.state
            })
        }
    }
}

extension ViewController {
    
    //creates some dummy models.
    func prepareDummyData() {
        
        var albums = [ListComponentItemType]()
        for idx in 0..<100 {
            
            if !randomChance() {
                //album
                let item = ListComponentItem<AlbumComponentView, Album>(state: Album(featured: idx < 4))
                item.delegate = self
                albums.append(item)
                
            } else {
                //video
                let item = ListComponentItem<VideoComponentView, Video>(state: Video())
                item.delegate = self
                albums.append(item)
            }
        }
        
        self.albums = albums
    }
    
}
