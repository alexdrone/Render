//
//  ListComponent.swift
//  Render
//
//  Created by Alex Usbergo on 27/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

public struct ListComponentItem {
    
    /// The reuse identifier for the component passed as argument.
    public let reuseIdentifier: String
    
    /// The component state.
    public let state: ComponentStateType
    
    /// Action for given index path
    public var action: ((NSIndexPath) -> Void)?
}

public class ListComponentView: UICollectionView {
    
    /// The data associated with this list.
    public var data = [ListComponentItem]() {
        didSet {
            //reload collection
        }
    }

    static func registerPrototype(reuseIdentifier: String, component: ComponentViewType) {
        
    }
    
}
