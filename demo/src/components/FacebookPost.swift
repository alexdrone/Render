import RenderNeutrino

protocol PostComponentDelegate: class {
  /// Fetches the comments associated to this post.
  func fetchComments(component: Post.PostComponent, post: Post.PostProps)
}

struct Post {

  private static func style(_ string: String) -> String {
    return "Post.\(string)"
  }

  class PostProps: UIProps {
    weak var delegate: PostComponentDelegate?

    enum FetchStatus { case notFetched, fetching, fetched }
    var fetchStatus: FetchStatus = .notFetched
    
    var id: String = NSUUID().uuidString.lowercased()
    var text: String = Random.sentence()
    var attachment: UIImage? = Random.image()
    var author: String = Random.name()
    var avatar: UIImage? = Random.avatar()
    var isLiked: Bool = false
    var numberOfLikes: Int = Random.integer(min: 0, max: 64)
    var numberOfComments: Int = Random.integer(min: 0, max: 32)
    var comments: [CommentProps] = [CommentProps(), CommentProps()]
  }

  class CommentProps: UIProps {
    var author: String = Random.name()
    var text: String = Random.sentence()
  }

  class PostState: UIState {
    var commentsExpanded: Bool = false
    var attachmentExpanded: Bool = false
  }

  class PostComponent: UIComponent<PostState, PostProps> {

    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      // Styles.
      return UINode<UIView>(reuseIdentifier: S.Post_wrapper.styleIdentifier,
                            styles: S.Post_wrapper.style).children([
        makeHeaderFragment(),
        makeBodyFragment(),
        makeAttachmentFragment(),
        makeStatsFragment(),
        makeCommentsFragment(),
      ])
    }

    /// Returns the author avatar and fullname fragment.
    private func makeHeaderFragment() -> UINode<UIView> {
      let props = self.props
      let header = UINode<UIView>(reuseIdentifier: S.Post_header.styleIdentifier,
                                  styles: S.Post_header.style)
      let headerTextWrapper = UINode<UIView>(styles: S.Post_headerTextWrapper.style)
      return header.children([
        UINode<UIImageView>(styles: S.Post_avatar.style){ $0.set(\UIImageView.image, props.avatar)},
        headerTextWrapper.children([
          UINode<UILabel>(styles: S.Post_authorName.style) { $0.set(\UILabel.text, props.author) },
          UINode<UILabel>(styles: S.Post_caption.style) { $0.set(\UILabel.text, "Just now") },
        ])
      ])
    }

    // The post body text fragment.
    private func makeBodyFragment() -> UINodeProtocol {
      let props = self.props
      return UINode<UILabel>(styles: S.Post_body.style) { $0.set(\UILabel.text, props.text) }
    }

    // The post attachment.
    private func makeAttachmentFragment() -> UINodeProtocol {
      let props = self.props
      let styles = S.Post_image.styleIdentifier.withModifiers([
        S.Modifier.Post_image_expanded: state.attachmentExpanded])

      return UINode<UIImageView>(styles: styles) {
        $0.set(\UIImageView.image, props.attachment)
        $0.set(\UIImageView.isUserInteractionEnabled, true)
        $0.view.onTap { [weak self] _ in
          guard let `self` = self else { return }
          self.state.attachmentExpanded = !self.state.attachmentExpanded
          self.setNeedsRender(options: [.animateLayoutChanges(animator: self.defaultAnimator())])
        }
      }
    }

    // The section with the number of comments and likes for this post.
    private func makeStatsFragment() -> UINodeProtocol {
      let props = self.props
      let wrapper = UINode<UIView>(reuseIdentifier: S.Post_stats.styleIdentifier,
                                   styles: S.Post_stats.style) {
        $0.view.onTap { [weak self] _ in
          guard let `self` = self, props.fetchStatus == .notFetched else { return }
          props.delegate?.fetchComments(component: self, post: props)
        }
      }
      return wrapper.children([
        UINode<UILabel>(styles: S.Post_numberOfLikes.style) {
          $0.set(\UILabel.text, "\(props.numberOfLikes) Likes")
        },
        UINode<UILabel>(styles: S.Post_numberOfComments.style) {
          $0.set(\UILabel.text, "\(props.numberOfComments) Comment")
        },
      ])
    }

    // Render the comment section according to the current *fetchStatus*.
    private func makeCommentsFragment() -> UINodeProtocol {
      guard let context = context else { return UINilNode.nil }
      let props = self.props
      switch props.fetchStatus {
      case .notFetched:
        return UINilNode.nil
      case .fetching:
        return UINode<UILabel>(styles: S.Post_commentsSpinner.style) {
          $0.set(\UILabel.text, "Loading...")
        }
      case .fetched:
        let wrapper = UINode<UIView>(reuseIdentifier: S.Post_commentsWrapper.styleIdentifier,
                                     styles: S.Post_commentsWrapper.style)
        wrapper.children(props.comments.map {
          context.transientComponent(CommentComponent.self,
                                     props: $0,
                                     parent: self).asNode()
        })
        return wrapper
      }
    }

    func defaultAnimator() -> UIViewPropertyAnimator {
      return UIViewPropertyAnimator(duration: 0.6, dampingRatio: 0.6, animations: nil)
    }
  }

  class CommentComponent: UIComponent<UINilState, CommentProps> {
    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      let props = self.props
      return UINode<UIView>(reuseIdentifier: S.Post_comment.styleIdentifier,
                            styles: S.Post_comment.style).children([
        UINode<UILabel>(styles: S.Post_commentAuthor.style) { $0.set(\UILabel.text, props.author) },
        UINode<UILabel>(styles: S.Post_commentLabel.style) { $0.set(\UILabel.text, props.text) }
      ])
    }
  }

  class FeedHeaderComponent: UIComponent<UINilState, UINilProps> {
    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      return UINode<UIView>(styles: S.Post_feedHeader.style).children([
        UINode<UILabel>(styles: S.Post_feedHeaderLabel.style) { $0.set(\UILabel.text, "Feed") },
      ])
    }
  }

}
