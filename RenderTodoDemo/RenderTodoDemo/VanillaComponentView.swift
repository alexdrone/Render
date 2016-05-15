//
//  VanillaAutolayoutComponentView.swift
//  RenderTodoDemo
//
//  Created by Alex Usbergo on 15/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit
import Render

// An example of a component implement through standard manual layout.
class VanillaComponentView: BaseComponentView {
    
    // If the component is used as list item it should be registered
    // as prototype for the infra.
    override class func initialize() {
        registerPrototype(component: VanillaComponentView())
    }
    
    /// The component state.
    var album: Album? {
        return self.state as? Album
    }
    
    var featured: Bool {
        return self.album?.featured ?? false
    }
    
    private lazy var avatar: UIImageView = UIImageView()
    private lazy var title: UILabel = UILabel()
    private lazy var subtitle: UILabel = UILabel()
    
    override func initalizeComponent() {
        self.backgroundColor = S.Color.black
        self.clipsToBounds = true
        
        self.title.textColor = S.Color.white
        self.title.font = S.Typography.mediumBold
        self.subtitle.textColor = S.Color.white
        self.subtitle.font = S.Typography.extraSmallLight
        self.addSubview(self.avatar)
        self.addSubview(self.title)
        self.addSubview(self.subtitle)
    }
    
    override func renderComponent(size: CGSize) {
        super.renderComponent(size)
        self.title.text = self.album?.artist
        self.subtitle.text = self.album?.title
        
        self.avatar.image = self.album?.cover
        self.layoutIfNeeded()
        
        // should set the size of the component here (bounded to 'size' passed in from the parent)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.avatar.frame = CGRect(x: 0, y: 0, width: 64, height: 64)
        self.title.frame = CGRect(x: CGRectGetMaxX(self.avatar.frame) + 8, y:0, width: self.parentSize.width, height: 32)
        self.subtitle.frame = CGRect(x: CGRectGetMaxX(self.avatar.frame) + 8, y:CGRectGetMaxY(self.title.frame), width: self.parentSize.width, height: 32)
        self.frame.size = CGSize(width: self.parentSize.width, height: 64)
    }
    
    
}