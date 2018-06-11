import UIKit
import RenderNeutrino

class FeedTableViewController: UITableComponentViewController, PostComponentDelegate {
  /// The model props to pass down to the component.
  lazy var posts: [Post.PostProps] = {
    var posts: [Post.PostProps] = Array(0...50).map { _ in
      let post = Post.PostProps()
      post.delegate = self
      return post
    }
    return posts
  }()

  /// Tells the data source to return the number of rows in a given section of a table view.
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return posts.count
  }

  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let post = posts[indexPath.row]
    let component = context.component(Post.PostComponent.self,
                                      key: post.id,
                                      props: post,
                                      parent: nil)
    return dequeueCell(forComponent: component)
  }

  /// If you'd like to have a section header, build one like so:
  /// - note: This is currently not supported when you have an expandable custom navigation bar.
  /*
  override func viewForHeader(inSection section: Int) -> UIView? {
    return UIView().install(component: context.transientComponent(Post.FeedHeaderComponent.self),
                            size: tableView.bounds.size)
  }
  */

  /// Called after the controller's view is loaded into memory.
  override func viewDidLoad() {
    styleNavigationBarComponent(title: "Feed")
    super.viewDidLoad()
    shouldApplyScrollRevealTransition = false

    // *tableHeaderView* and *tableFooterView* can be built from components too.
    self.tableView.tableHeaderView = UIView().install(
      component: context.transientComponent(Post.FeedHeaderComponent.self),
      size: tableView.bounds.size)
  }
}
