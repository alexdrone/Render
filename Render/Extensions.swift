//
//  Extensions.swift
//  FlexboxLayout
//
//  Created by Alex Usbergo on 30/03/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit
    
extension FlexboxView where Self: UIView {

    internal func postRender() {
        
        // content-size calculation for the scrollview should be applied after the layout
        if let scrollView = self as? UIScrollView {
            if let _ = self as? UITableView { return }
            if let _ = self as? UICollectionView { return }
            scrollView.postRender()
        }
    }
}

extension UIScrollView {
    
    private func postRender() {
        var x: CGFloat = 0
        var y: CGFloat = 0
        for subview in self.subviews {
            x = CGRectGetMaxX(subview.frame) > x ? CGRectGetMaxX(subview.frame) : x
            y = CGRectGetMaxY(subview.frame) > y ? CGRectGetMaxY(subview.frame) : y
        }
        self.contentSize = CGSize(width: x, height: y)
        self.scrollEnabled = true
    }
}

private var __internalStoreHandle: UInt8 = 0
private var __cacheHandle: UInt8 = 0

