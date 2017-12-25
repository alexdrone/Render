import UIKit
import RenderNeutrino

class FeedViewController: UIComponentViewController<Feed.FeedComponent>,
                          PostComponentDelegate {
  lazy var feed: Feed.FeedProps = {
    var posts: [Post.PostProps] = []
    for _ in 0...10 {
      let post = Post.PostProps()
      post.delegate = self
      posts.append(post)
    }
    let feed = Feed.FeedProps()
    feed.posts = posts
    return feed
  }()

  /// Subclasses should override this method and constructs the root component by using the view
  /// controller context.
  override func buildRootComponent() -> Feed.FeedComponent {
    let component = context.component(Feed.FeedComponent.self,
                                      props: self.feed,
                                      parent: nil)
    component.delegate = self
    return component
  }

  /// Called after the controller's view is loaded into memory.
  override func viewDidLoad() {
    super.viewDidLoad()
    shouldRenderAlongsideSizeTransitionAnimation = true
    styleNavigationBar()
  }
}
