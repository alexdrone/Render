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
      let wrapperStyle = style("wrapper")
      return UINode<UIView>(reuseIdentifier: wrapperStyle, styles: [wrapperStyle]).children([
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
      // Styles.
      let headerStyle = style("header")
      let headerTextWrapperStyle = style("headerTextWrapper")
      let avatarStyle = style("avatar")
      let authorNameStyle = style("authorName")
      let captionStyle = style("caption")

      let header = UINode<UIView>(reuseIdentifier: headerStyle, styles: [headerStyle])
      let headerTextWrapper = UINode<UIView>(styles: [headerTextWrapperStyle])
      return header.children([
        UINode<UIImageView>(reuseIdentifier: avatarStyle, styles: [avatarStyle]) {
          $0.set(\UIImageView.image, props.avatar)
        },
        headerTextWrapper.children([
          UINode<UILabel>(styles: [authorNameStyle]) { $0.set(\UILabel.text, props.author) },
          UINode<UILabel>(styles: [captionStyle]) { $0.set(\UILabel.text, "Just now") },
        ])
      ])
    }

    // The post body text fragment.
    private func makeBodyFragment() -> UINodeProtocol {
      let props = self.props
      let bodyStyle = style("body")

      return UINode<UILabel>(styles: [bodyStyle]) { $0.set(\UILabel.text, props.text) }
    }

    // The post attachment.
    private func makeAttachmentFragment() -> UINodeProtocol {
      let props = self.props
      let styles = style("image").withModifiers(["expanded": state.attachmentExpanded])

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
      // Styles.
      let statsStyle = style("stats")
      let numberOfLikesStyle = style("numberOfLikes")
      let numberOfCommentsStyle = style("numberOfComments")

      let wrapper = UINode<UIView>(reuseIdentifier: statsStyle, styles: [statsStyle]) {
        $0.view.onTap { [weak self] _ in
          guard let `self` = self, props.fetchStatus == .notFetched else { return }
          props.delegate?.fetchComments(component: self, post: props)
        }
      }
      return wrapper.children([
        UINode<UILabel>(styles: [numberOfLikesStyle]) {
          $0.set(\UILabel.text, "\(props.numberOfLikes) Likes")
        },
        UINode<UILabel>(styles: [numberOfCommentsStyle]) {
          $0.set(\UILabel.text, "\(props.numberOfComments) Comment")
        },
      ])
    }

    // Render the comment section according to the current *fetchStatus*.
    private func makeCommentsFragment() -> UINodeProtocol {
      guard let context = context else { return UINilNode.nil }
      let props = self.props
      // Styles.
      let commentsSpinnerStyle = style("commentsSpinner")
      let commentsWrapperStyle = style("commentsWrapper")

      switch props.fetchStatus {
      case .notFetched:
        return UINilNode.nil
      case .fetching:
        return UINode<UILabel>(styles: [commentsSpinnerStyle]) {
          $0.set(\UILabel.text, "Loading...")
        }
      case .fetched:
        let wrapper = UINode<UIView>(styles: [commentsWrapperStyle])
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
      // Styles.
      let commentStyle = style("comment")
      let commentAuthorStyle = style("commentAuthor")
      let commentLabelStyle = style("commentLabel")

      return UINode<UIView>(reuseIdentifier: commentStyle, styles: [commentStyle]).children([
        UINode<UILabel>(styles: [commentAuthorStyle]) {
          $0.set(\UILabel.text, props.author)
        },
        UINode<UILabel>(styles: [commentLabelStyle]) {
          $0.set(\UILabel.text, props.text)
        }
      ])
    }
  }

  class FeedHeaderComponent: UIComponent<UINilState, UINilProps> {

    /// Builds the node hierarchy for this component.
    override func render(context: UIContextProtocol) -> UINodeProtocol {
      // Styles.
      let feedHeaderStyle = style("feedHeader")
      let feedHeaderLabelStyle = style("feedHeaderLabel")

      return UINode<UIView>(styles: [feedHeaderStyle]).children([
        UINode<UILabel>(styles: [feedHeaderLabelStyle]) { $0.set(\UILabel.text, "Feed") },
      ])
    }
  }

}
