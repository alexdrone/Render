//
//  ComponentTableView.swift
//  Render
//
//  Created by Alex Usbergo on 07/05/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

//
//  ComponentCollectionView.swift
//  Render
//
//  Created by Alex Usbergo on 27/04/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

public class ComponentTableView: UITableView {
    
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
    private var diffCalculator: TableViewDiffCalculator<EquatableWrapper>!
    
    /// The component configuration.
    private var configuration: ((ComponentViewType) -> Void)?
    
    /// Initializes and returns a newly allocated collection view object with the specified frame and layout.
    /// - returns: An initialized collection view object or nil if the object could not be created.
    
    public required convenience init() {
       self.init(frame: CGRect.zero, style: .Plain)
    }
    
    override init(frame: CGRect, style: UITableViewStyle) {
        
        super.init(frame: frame, style: style)
        
        self.diffCalculator = TableViewDiffCalculator(tableView: self, initialRows: self.items.map({ return EquatableWrapper(item: $0) }))

        // automatic dimensions (with a default estimate)
        self.rowHeight = UITableViewAutomaticDimension
        self.separatorStyle = .None
        self.separatorColor = UIColor.clearColor()
        
        self.dataSource = self
        self.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ComponentTableView: ComponentViewType {
    
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
            self.renderVisibleComponents()
        }
    }
}

extension ComponentTableView: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let item = self.items[indexPath.row]
        
        let cell: ComponentTableViewCell! =  tableView.dequeueReusableCellWithIdentifier(item.reuseIdentifier) as? ComponentTableViewCell ??
                                             ComponentTableViewCell(reuseIdentifier: item.reuseIdentifier, component: item.newComponentIstance())
        
        cell.state = item.itemState
        cell.renderComponent(CGSize(tableView.bounds.size.width))
        return cell
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return prototypeSize(self, state: self.items[indexPath.row]).height
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let state = self.items[indexPath.row]
        state.delegate?.didSelectItem(state, indexPath: indexPath, listComponent: self)
    }    
}


