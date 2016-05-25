import UIKit
import XCPlayground
import Render

/*:
 ![logo](logo_small.png)
 # Components embedded in cells
 
 You can wrap your components in `ComponentTableViewCell` or `ComponentCollectionViewCell` and use 
 the classic dataSource/delegate pattern for you view controller.
 */

class FooState: ComponentStateBase {
    let text: String = randomString(randomInt(0, max: 100))
}

class FooComponentView: ComponentView {
    
    override class func initialize() {
        
        // if we intend to use this component inside of a cell
        // we have to register an instance as a prototype for the infra.
        // The 'initialize' function seems to be a convenient palce to do it.
        ComponentPrototypes.registerComponentPrototype(component: FooComponentView())
    }
    
    // we cast the state for convenience
    var fooState: FooState {
        return  (self.state as? FooState) ?? FooState()
    }

    override func construct() -> ComponentNodeType {
        let margin: Float = 4.0
        let insets: Inset = (margin, margin, margin, margin, margin, margin)
        return ComponentNode<UIView>().configure({ view in
            view.style.flexDirection = .Row
            view.style.margin = insets
            
            // that's how we can define the size in relation to the size of the parent view.
            let min = ~self.referenceSize.width
            view.style.minDimensions.width = max(min, 96)
            
            view.backgroundColor = UIColor.A
        }).children([
            ComponentNode<UIView>().configure({ view in
                view.style.dimensions = (32, 32)
                view.style.margin = insets
                view.backgroundColor = UIColor.B
                view.layer.cornerRadius = 16
            }),
            ComponentNode<UILabel>().configure({ view in
                view.style.margin = insets
                view.style.alignSelf = .Center
                view.style.flex = Flex.Max
                view.text = self.fooState.text
                view.numberOfLines = 0
                view.font = UIFont.systemFontOfSize(12.0, weight: UIFontWeightLight)
            })
        ])
    }
}

/*: Now this is how we wrap the component inside a `ComponentTableViewCell` in our datasource */

class DataSource: NSObject, UITableViewDataSource {
    
    let items: [FooState] = {
        var items = [FooState]()
        for _ in 0..<6 {
            items.append(FooState())
        }
        return items
    }()
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell  = tableView.dequeueReusableCellWithIdentifier(String(ComponentTableViewCell<FooComponentView>.self), forIndexPath: indexPath) as! ComponentTableViewCell<FooComponentView>
        cell.mountComponentIfNecessary(FooComponentView())
        cell.component?.state = items[indexPath.row]
        
        //and render the component
        cell.renderComponent(CGSize.sizeConstraintToWidth(tableView.bounds.size.width))
        return cell
    }
}

/*: And finally create a `UITableView`  */

let tableView = UITableView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 320, height: 320)))

tableView.registerClass(ComponentTableViewCell<FooComponentView>.self, forCellReuseIdentifier: String(ComponentTableViewCell<FooComponentView>.self))

//we want automatic dimensions for our cells
tableView.rowHeight = UITableViewAutomaticDimension

//this improves drastically the performance of reloadData when you have a large collection of items
tableView.estimatedRowHeight = 100

let dataSource = DataSource()
tableView.dataSource = dataSource
tableView.reloadData()

snapshot(tableView)

