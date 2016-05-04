//
//  ListComponent.swift
//  Render
//
//  Created by Alex Usbergo on 27/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

public class ListComponentView: UICollectionView {

    /// The data associated with this list.
    public var items = [ListComponentItemType]() {
        didSet {
            self.reloadData()
            self.renderComponent(CGSize.undefined)
        }
    }

    private var configuration: ((ComponentViewType) -> Void)?
    
    /// Initializes and returns a newly allocated collection view object with the specified frame and layout.
    /// - returns: An initialized collection view object or nil if the object could not be created.
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout = UICollectionViewFlowLayout()) {
        
        let flow: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flow.minimumInteritemSpacing = 0;
        flow.minimumLineSpacing = 0;
        
        super.init(frame: frame, collectionViewLayout: layout ?? flow)
        self.dataSource = self
        self.delegate = self
        self.layoutMargins = UIEdgeInsets()
        
        for (key,_) in prototypes {
            self.registerClass(ComponentCollectionViewCell.self, forCellWithReuseIdentifier: key)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ListComponentView: ComponentViewType {

    /// Applies the component configuration (as per ViewType extension)
    /// - Note: If your view is a custom 'ComponentViewType' class (Not inheriting from BaseComponentView)
    /// then you are expected to store this closure and run it when 'renderComponent' is called.
    public func configure(closure: ((ComponentViewType) -> Void)) {
        self.configuration = closure
    }
    
    /// The state of this component.
    public var state: ComponentStateType? {
        get {
            return ListComponentState(items: items)
        }
        set {
            self.items = (newValue as? ListComponentView)?.items ?? [ListComponentItemType]()
        }
    }
    
    /// The parent for this component.
    public var parentView: UIView? {
        get {
            return self.superview
        }
        set {
            //nop
        }
    }

    /// Render the component.
    /// - parameter size: The bounding box for this component. The default will determine the intrinsic content
    /// size for this component.
    /// - parameter state: The (optional) state for this component.
    public func renderComponent(size: CGSize) {
        self.collectionViewLayout.invalidateLayout()
    }
    
}

extension ListComponentView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    /// Asks your data source object for the cell that corresponds to the specified item in the collection view.
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    /// Asks your data source object for the cell that corresponds to the specified item in the collection view.
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
        let state = self.items[indexPath.row]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.items[indexPath.row].reuseIdentifier, forIndexPath: indexPath) as! ComponentCollectionViewCell

        // mounts the component (if necessary)
        if !cell.hasMountedComponent() {
            let component = state.newComponentIstance()
            component.parentView = self
            cell.mountComponentIfNecessary(component)
        }
        
        // configure the cell with
        if let configuration = state.configuration {
            cell.component?.configure(configuration)
        }

        cell.state = state.itemState

        return cell
    }
    
    /// Asks the delegate for the size of the specified item’s cell.
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let state = self.items[indexPath.row]
        guard let component = prototypes[state.reuseIdentifier] else {
            fatalError("Unregistered component with reuse identifier \(state.reuseIdentifier).")
        }

        // render the component.
        component.state = state.itemState
        component.parentView = self
        component.renderComponent(CGSize(self.bounds.size.width))
        
        if let view = component as? UIView {
            return view.bounds.size
        } else {
            return CGSize.zero
        }
    }

    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let state = self.items[indexPath.row]
        state.delegate?.didSelectItem(state, indexPath: indexPath, listComponent: self)
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

