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

    override func construct() -> NodeType {
        let margin: Float = 4.0
        let insets: Inset = (margin, margin, margin, margin, margin, margin)
        return Node<UIView>().configure({ view in
            view.useFlexbox = true
            view.layout_flexDirection = .row
            view.layout_marginAll = insets
            view.layout_minWidth = max(self.referenceSize.widt, 98)
            view.backgroundColor = UIColor.A
        }).children([
            Node<UIView>().configure({ view in
                view.useFlexbox = true
                view.layout_width = 32
                view.layout_height = 32
                view.layout_marginAll = insets
                view.backgroundColor = UIColor.B
                view.layer.cornerRadius = 16
            }),
            Node<UILabel>().configure({ view in
                view.useFlexbox = true
                view.layout_marginAll = insets
                view.layout_alignSelf = .center
                view.layout_flexGrow = 1
                view.text = self.fooState.text
                view.numberOfLines = 0
                view.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightLight)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell  = tableView.dequeueReusableCell(withIdentifier: String(describing: ComponentTableViewCell<FooComponentView>.self), for: indexPath) as! ComponentTableViewCell<FooComponentView>
        cell.mountComponentIfNecessary(FooComponentView())
        cell.component?.state = items[indexPath.row]
        
        //and render the component
        cell.renderComponent(CGSize.sizeConstraintToWidth(tableView.bounds.size.width))
        return cell
    }
}

/*: And finally create a `UITableView`  */

let tableView = UITableView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 320, height: 320)))

tableView.register(ComponentTableViewCell<FooComponentView>.self, forCellReuseIdentifier: String(describing: ComponentTableViewCell<FooComponentView>.self))

//we want automatic dimensions for our cells
tableView.rowHeight = UITableViewAutomaticDimension

//this improves drastically the performance of reloadData when you have a large collection of items
tableView.estimatedRowHeight = 100

let dataSource = DataSource()
tableView.dataSource = dataSource
tableView.reloadData()

snapshot(tableView)

