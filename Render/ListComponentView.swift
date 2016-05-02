//
//  ListComponent.swift
//  Render
//
//  Created by Alex Usbergo on 27/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

public class ListComponentItem<C: ComponentViewType, S: ComponentStateType>: ListComponentItemType {

    /// The reuse identifier for the component passed as argument.
    public var reuseIdentifier: String
    
    /// The component state.
    public var itemState: ComponentStateType
    public var state: S {
        return self.itemState as! S
    }
    
    /// Additional configuration closure for the component
    public var configuration: ((ComponentViewType) -> Void)?
    
    /// Initialise a new component with
    public init(reuseIdentifier: String = String(C), state: S, configuration: ((ComponentViewType) -> Void)? = nil) {
        self.reuseIdentifier = reuseIdentifier
        self.itemState = state
        self.configuration = configuration
    }

    /// Creates a new instance for the associated component
    public func newComponentIstance() -> ComponentViewType {
        return C() as ComponentViewType
    }
}

public class ListComponentView: UICollectionView {

    /// The data associated with this list.
    public var data = [ListComponentItemType]() {
        didSet {
            self.renderComponent()
        }
    }
    
    /// Initializes and returns a newly allocated collection view object with the specified frame and layout.
    /// - returns: An initialized collection view object or nil if the object could not be created.
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout = UICollectionViewFlowLayout()) {
        super.init(frame: frame, collectionViewLayout: layout)
        self.dataSource = self
        self.delegate = self
        
        for (key,_) in prototypes {
            self.registerClass(ComponentCollectionViewCell.self, forCellWithReuseIdentifier: key)
        }
    }
    
    /// Reload the list
    public func renderComponent() {
        self.reloadData()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ListComponentView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    /// Asks your data source object for the cell that corresponds to the specified item in the collection view.
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.data.count
    }
    
    /// Asks your data source object for the cell that corresponds to the specified item in the collection view.
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
        let state = self.data[indexPath.row]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.data[indexPath.row].reuseIdentifier, forIndexPath: indexPath) as! ComponentCollectionViewCell

        if !cell.hasMountedComponent() {
            let component = state.newComponentIstance()
            cell.mountComponentIfNecessary(component)
        }
        
        if let configuration = state.configuration {
            cell.component?.configure(configuration)
        }
        
        cell.state = state.itemState
        return cell
    }
    
    /// Asks the delegate for the size of the specified item’s cell.
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let state = self.data[indexPath.row]
        guard let component = prototypes[state.reuseIdentifier] else {
            fatalError("Unregistered component with reuse identifier \(state.reuseIdentifier).")
        }
    
        component.renderComponent(CGSize(self.bounds.size.width))
        
        if let view = component as? UIView {
            return view.bounds.size
        } else {
            return CGSize.zero
        }
    }

}

/// The collection of registered prototypes
private var prototypes = [String: ComponentViewType]()

extension ListComponentView {
    
    /// Register the component as a reusable component in the list component.
    /// - parameter reuseIdentifier: The identifier for this component. The default is the component class name.
    /// - parameter component: An instance of the component.
    public static func registerPrototype<C:ComponentViewType>(reuseIdentifier: String = String(C), component: C) {
        prototypes[reuseIdentifier] = component
    }
}

