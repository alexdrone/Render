//
//  ComponentCollectionView.swift
//  Render
//
//  Created by Alex Usbergo on 27/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

public class ComponentCollectionView: UICollectionView {
    
    /// The data associated with this list.
    public var items = [ListComponentItemType]() {
        didSet {
            let startTime = CFAbsoluteTimeGetCurrent()
            if self.updateWithDiff {
                self.diffCalculator.rows = self.items.map({ return EquatableWrapper(item: $0) })
            } else {
                self.reloadData()
            }
            defer {
                debugRenderTime("\(self.dynamicType).diff for items", startTime: startTime, threshold: 500)
            }
        }
    }
    
    /// The state of this component.
    public var state: ComponentStateType?
    
    /// Whether to use or not a diff algorithm when the items are set.
    /// Default is true.
    public var updateWithDiff: Bool = true
    lazy private var diffCalculator: CollectionViewDiffCalculator<EquatableWrapper> = {
        return CollectionViewDiffCalculator(collectionView: self, initialRows: self.items.map({ return EquatableWrapper(item: $0) }))
    }()
    
    /// The estimated size of cells in the collection view.
    /// Providing an estimated cell size can improve the performance of the collection view when the cells adjust their size dynamically. 
    /// Specifying an estimate value lets the collection view defer some of the calculations needed to determine the actual size of its content.
    /// Specifically, cells that are not onscreen are assumed to be the estimated height.
    public var estimatedItemSize: CGSize {
        get {
            return (self.collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize ?? CGSize.zero
        }
        set {
            (self.collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize = newValue
        }
    }
    
    /// The component configuration.
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

extension ComponentCollectionView: ComponentViewType {

    /// Applies the component configuration (as per ViewType extension)
    /// - Note: If your view is a custom 'ComponentViewType' class (Not inheriting from BaseComponentView)
    /// then you are expected to store this closure and run it when 'renderComponent' is called.
    public func configure(closure: ((ComponentViewType) -> Void)) {
        self.configuration = closure
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
        self.configuration?(self)
        if size != self.parentSize {
            self.collectionViewLayout.invalidateLayout()
        }
    }
}

extension ComponentCollectionView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
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
        return prototypeSize(self, state: self.items[indexPath.row])
    }

    /// Tells the delegate that the item at the specified index path was selected.
    /// The collection view calls this method when the user successfully selects an item in the collection view.
    /// It does not call this method when you programmatically set the selection.
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let state = self.items[indexPath.row]
        state.delegate?.didSelectItem(state, indexPath: indexPath, listComponent: self)
    }
}



