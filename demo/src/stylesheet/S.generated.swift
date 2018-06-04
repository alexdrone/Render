import UIKit
import RenderNeutrino
public struct S {
  public enum Typography: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Typography"
    public static let style: [String] = [Typography.styleIdentifier]
    case extraSmallBold
    case smallBold
    case small
    case medium
    case mediumBold
  }
  public enum Counter_button_even: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Counter.button.even"
    public static let style: [String] = [Counter_button_even.styleIdentifier]
    case backgroundColorImage
  }
  public enum TrackNavigationBar_circle: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "TrackNavigationBar.circle"
    public static let style: [String] = [TrackNavigationBar_circle.styleIdentifier]
    case backgroundColor
    case font
    case textColor
    case textAlignment
  }
  public enum Track_wrapper: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Track.wrapper"
    public static let style: [String] = [Track_wrapper.styleIdentifier]
    case width
    case backgroundColor
    case height
    case flexDirection
    case alignItems
  }
  public enum Palette: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Palette"
    public static let style: [String] = [Palette.styleIdentifier]
    case primaryAccent
    case primary
    case primaryText
    case secondary
    case accent
    case accentText
    case text
    case white
  }
  public enum Post_comment: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.comment"
    public static let style: [String] = [Post_comment.styleIdentifier]
    case backgroundColor
    case padding
    case paddingLeft
    case paddingRight
    case margin
    case cornerRadius
    case minHeight
  }
  public enum Post_avatar: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.avatar"
    public static let style: [String] = [Post_avatar.styleIdentifier]
    case width
    case height
    case cornerRadius
  }
  public enum Track_title: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Track.title"
    public static let style: [String] = [Track_title.styleIdentifier]
    case width
    case margin
    case font
    case textColor
    case numberOfLines
  }
  public enum MyPalette: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "MyPalette"
    public static let style: [String] = [MyPalette.styleIdentifier]
    case background
    case text
  }
  public enum Counter_button: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Counter.button"
    public static let style: [String] = [Counter_button.styleIdentifier]
    case animator
    case backgroundColorImage
    case font
    case padding
    case width
    case height
    case alignSelf
    case margin
    case depthPreset
    case cornerRadius
  }
  public enum Post_numberOfLikes: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.numberOfLikes"
    public static let style: [String] = [Post_numberOfLikes.styleIdentifier]
    case font
    case textColor
    case margin
  }
  public enum Counter_wrapper: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Counter.wrapper"
    public static let style: [String] = [Counter_wrapper.styleIdentifier]
    case backgroundColor
    case justifyContent
    case width
  }
  public enum Post_image_expanded: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.image.expanded"
    public static let style: [String] = [Post_image_expanded.styleIdentifier]
    case height
  }
  public enum TrackNavigationBar_button: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "TrackNavigationBar.button"
    public static let style: [String] = [TrackNavigationBar_button.styleIdentifier]
    case width
    case height
    case position
    case cornerRadius
    case backgroundColorImage
    case font
    case borderWidth
    case borderColor
  }
  public enum Margin: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Margin"
    public static let style: [String] = [Margin.styleIdentifier]
    case xsmall
    case small
    case medium
    case large
  }
  public enum Post_commentAuthor: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.commentAuthor"
    public static let style: [String] = [Post_commentAuthor.styleIdentifier]
    case textColor
    case font
    case margin
    case numberOfLines
  }
  public enum FacebookPalette: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "FacebookPalette"
    public static let style: [String] = [FacebookPalette.styleIdentifier]
    case white
    case blue
    case lightGray
    case gray
    case black
  }
  public enum FacebookTypography: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "FacebookTypography"
    public static let style: [String] = [FacebookTypography.styleIdentifier]
    case title
    case caption
    case text
    case button
    case small
  }
  public enum Simple_label: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Simple.label"
    public static let style: [String] = [Simple_label.styleIdentifier]
    case font
    case textColor
    case margin
  }
  public enum Post_caption: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.caption"
    public static let style: [String] = [Post_caption.styleIdentifier]
    case font
    case textColor
  }
  public enum Post_commentsSpinner: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.commentsSpinner"
    public static let style: [String] = [Post_commentsSpinner.styleIdentifier]
    case margin
    case font
    case textColor
    case justifyContent
    case textAlignment
  }
  public enum Post_statsLabel: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.statsLabel"
    public static let style: [String] = [Post_statsLabel.styleIdentifier]
    case font
    case textColor
    case margin
  }
  public enum Simple_container: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Simple.container"
    public static let style: [String] = [Simple_container.styleIdentifier]
    case backgroundColor
    case width
    case justifyContent
  }
  public enum Post_image: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.image"
    public static let style: [String] = [Post_image.styleIdentifier]
    case width
    case height
    case clipsToBounds
    case contentMode
  }
  public enum Post_commentLabel: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.commentLabel"
    public static let style: [String] = [Post_commentLabel.styleIdentifier]
    case textColor
    case font
    case margin
    case numberOfLines
  }
  public enum Post_header: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.header"
    public static let style: [String] = [Post_header.styleIdentifier]
    case flexDirection
    case alignItems
    case padding
  }
  public enum Counter_label: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Counter.label"
    public static let style: [String] = [Counter_label.styleIdentifier]
    case font
    case color
    case textAlignment
    case padding
  }
  public enum Post_feedHeader: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.feedHeader"
    public static let style: [String] = [Post_feedHeader.styleIdentifier]
    case backgroundColor
    case width
    case height
  }
  public enum Post_feedHeaderLabel: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.feedHeaderLabel"
    public static let style: [String] = [Post_feedHeaderLabel.styleIdentifier]
    case textColor
    case font
    case textAlignment
    case alignSelf
    case height
  }
  public enum TrackNavigationBar_main: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "TrackNavigationBar.main"
    public static let style: [String] = [TrackNavigationBar_main.styleIdentifier]
    case justifyContent
    case alignSelf
    case alignItems
  }
  public enum Post_commentsWrapper: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.commentsWrapper"
    public static let style: [String] = [Post_commentsWrapper.styleIdentifier]
    case width
    case backgroundColor
  }
  public enum Post_stats: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.stats"
    public static let style: [String] = [Post_stats.styleIdentifier]
    case height
    case flexDirection
  }
  public enum Track_cover: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Track.cover"
    public static let style: [String] = [Track_cover.styleIdentifier]
    case height
    case width
    case cornerRadius
    case marginLeft
  }
  public enum Post_wrapper: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.wrapper"
    public static let style: [String] = [Post_wrapper.styleIdentifier]
    case width
    case backgroundColor
  }
  public enum Post_headerTextWrapper: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.headerTextWrapper"
    public static let style: [String] = [Post_headerTextWrapper.styleIdentifier]
    case flexDirection
    case marginLeft
    case flexGrow
    case flexShrink
  }
  public enum Post_authorName: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.authorName"
    public static let style: [String] = [Post_authorName.styleIdentifier]
    case font
    case textColor
  }
  public enum Post_numberOfComments: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.numberOfComments"
    public static let style: [String] = [Post_numberOfComments.styleIdentifier]
    case textColor
    case font
    case margin
  }
  public enum TrackPalette: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "TrackPalette"
    public static let style: [String] = [TrackPalette.styleIdentifier]
    case white
    case gray
    case green
    case black
    case lightBlack
  }
  public enum Post_body: String, UIStylesheetProtocol {
    public static let styleIdentifier: String = "Post.body"
    public static let style: [String] = [Post_body.styleIdentifier]
    case font
    case textColor
    case numberOfLines
    case margin
  }
  public struct Modifier {
    public static let Counter_button_even = "even"
    public static let Post_image_expanded = "expanded"
  }
}