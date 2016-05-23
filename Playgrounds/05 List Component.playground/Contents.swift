import UIKit
import XCPlayground
import Render

/*:
 ![logo](logo_small.png)
 # ComponentTableView/CollectionView
 
 Although the approach shown above works perfectly, it does clashes with the React-like component pattern.
 `ComponentTableView` and `ComponentCollectionView` expose the same interface and work with a simple array of `ListComponentItemType` (see also `ListComponentItem<ComponentViewType, ComponentStateType>: ListComponentItemType`).
 ComponentTableView/CollectionView takes care of cell reuse for you and apply a diff algorithm when the `items` property is set (so that proper insertions/deletions are performed rather than  `reloadData() `).

 */

func ==(lhs: Album, rhs: Album) -> Bool {
    return lhs.id == rhs.id
}
class Album: ComponentStateBase {
    let id = NSUUID().UUIDString
    let title: String = "Foo"
    let artist: String = "Bar"
    let cover: UIImage = UIImage(named: "logo_rect")!
    var featured: Bool
    
    init(featured: Bool = false) {
        self.featured = featured
    }
}

// This will just improve the performance in list diffs.
extension Album: ComponentStateTypeUniquing {
    var stateUniqueIdentifier: String {
        return self.id
    }
}

class AlbumComponentView: ComponentView {
    
    // If the component is used as list item it should be registered
    // as prototype for the infra.
    override class func initialize() {
        registerPrototype(component: AlbumComponentView())
    }
    
    /// The component state.
    var album: Album? { return self.state as? Album  }
    var featured: Bool { return self.album?.featured ?? false }
    
    /// Constructs the component tree.
    override func construct() -> ComponentNodeType {
        return ComponentNode<UIView>().configure({ view in
            view.style.flexDirection = self.featured ? .Column : .Row
            view.backgroundColor = UIColor.blackColor()
            view.style.dimensions.width = self.featured ? ~self.parentSize.width/2 : ~self.parentSize.width
            view.style.dimensions.height = self.featured ? Undefined : 64
        }).children([
            ComponentNode<UIImageView>().configure({ view in
                view.image = self.album?.cover
                view.style.alignSelf = .Center
                view.style.dimensions.width = self.featured ? ~self.parentSize.width/2 : 48
                view.style.dimensions.height = self.featured ? view.style.dimensions.width : 48
            }),
            ComponentNode<UIView>().configure({ view in
                view.style.flexDirection = .Column
                view.style.margin = (0.0, 4.0, 0.0, 4.0, 4.0, 4.0)
                view.style.alignSelf = .Center
                
            }).children([
                ComponentNode<UILabel>().configure({ view in
                    view.style.margin = (0.0, 4.0, 0.0, 4.0, 4.0, 4.0)
                    view.text = self.album?.title ?? "None"
                    view.textColor = UIColor.whiteColor()
                })
            ])
        ])
    }
}

class ListDemoViewController: UIViewController {
    
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
            view.backgroundColor = UIColor.blackColor()
            view.items = self.albums
        }
        self.view.addSubview(self.listComponentView)
    }
    
    /// Called to notify the view controller that its view has just laid out its subviews.
    override func viewDidLayoutSubviews() {
        self.listComponentView.renderComponent(self.view.bounds.size)
    }
}

extension ListDemoViewController {
    
    //creates some dummy models.
    func prepareDummyData() {
        var albums = [ListComponentItemType]()
        for idx in 0..<4 {
            let item = ListComponentItem<AlbumComponentView, Album>(state: Album(featured: idx < 2))
            albums.append(item)
        }
        self.albums = albums
    }
}

let vc = ListDemoViewController()
vc.view.frame = CGRect(origin: CGPoint.zero, size:CGSize(width: 500, height: 500))

vc.view



