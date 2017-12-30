import UIKit
import RenderNeutrino

class FeedTableViewController: UITableComponentViewController, PostComponentDelegate {
  /// The model props to pass down to the component.
  lazy var posts: [Post.PostProps] = {
    var posts: [Post.PostProps] = Array(0...100).map { _ in
      let post = Post.PostProps()
      post.delegate = self
      return post
    }
    return posts
  }()


  /// Tells the data source to return the number of rows in a given section of a table view.
  override func numberOfComponents(in section: Int) -> Int {
    return posts.count
  }

  /// Must return the desired component for at the given index path.
  override func component(for indexPath: IndexPath) -> UIComponentProtocol? {
    let post = posts[indexPath.row]
    let component = context.component(Post.PostComponent.self,
                                      key: post.id,
                                      props: post,
                                      parent: nil)
    component.delegate = self
    return component
  }

  /// Returns the desired reuse identifier for the cell with the index path passed as argument.
  override func reuseIdentifier(for indexPath: IndexPath) -> String {
    return "post"
  }

  /// Called after the controller's view is loaded into memory.
  override func viewDidLoad() {
    super.viewDidLoad()
    shouldApplyDefaultScrollRevealAnimation = true
  }
}
