import UIKit
import RenderNeutrino

class SinglePostViewController: UIScrollableComponentViewController<Post.PostComponent>,
                                PostComponentDelegate {
  let post = Post.PostProps()

  /// Subclasses should override this method and constructs the root component by using the view
  /// controller context.
  override func buildRootComponent() -> Post.PostComponent {
    post.delegate = self
    let component = context.component(Post.PostComponent.self,
                                      key: post.id,
                                      props: post,
                                      parent: nil)
    component.delegate = self
    return component
  }

  /// Called after the controller's view is loaded into memory.
  override func viewDidLoad() {
    // Configure custom navigation bar.
    styleNavigationBarComponent(title: "Post of the day")
    super.viewDidLoad()
    shouldRenderAlongsideSizeTransitionAnimation = true
  }
}

extension PostComponentDelegate {
  /// Fetches the comments associated to this post.
  func fetchComments(component: Post.PostComponent, post: Post.PostProps) {
    // Render the *fetching* state.
    post.fetchStatus = .fetching
    component.setNeedsRender(options: [
      .animateLayoutChanges(animator: component.defaultAnimator())
      ])
    // Creates some fake comments.
    var comments: [Post.CommentProps] = []
    for _ in 0..<post.numberOfComments { comments.append(Post.CommentProps()) }
    post.comments = comments
    // Simulate some loading time and then renders the *fetched* state.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      post.fetchStatus = .fetched
      component.setNeedsRender(options: [
        .animateLayoutChanges(animator: component.defaultAnimator())
      ])
    }
  }
}

