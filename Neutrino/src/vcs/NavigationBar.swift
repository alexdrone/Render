import UIKit

// MARK: - UINavigationBarProps

open class UINavigationBarProps: UIProps {

  /// A button specialized for placement in the navigation bar.
  public struct BarButtonItem {
    /// The icon that is going to be used for this button.
    public var icon: UIImage
    /// The optional bar button title.
    /// - note: The label is going to be rendered with *UINavigationBarProps.style.tintColor* as its
    /// text color and with *UINavigationBarProps.style.buttonFont* as its font.
    public var title: String?
    /// Fallbacks on the 'title' if nothing is defined.
    public var accessibilityLabel: String?
    /// Closure executed whenever the button is tapped.
    public var onSelected: () -> (Void)
    /// A custom node that is going to be used to render the element.
    /// - note: All of the previous properties are going to be ignored when this is not 'nil'.
    public var customNode: ((UINavigationBarProps, UINavigationBarState) -> UINodeProtocol)?
    /// When the items is disabled is not going to be rendered in the navigation bar.
    public var disabled: Bool = false

    /// Creates a new bar button.
    public init(icon: UIImage,
                title: String? = nil,
                accessibilityLabel: String? = nil,
                onSelected: @escaping () -> Void) {
      self.icon = icon
      self.title = title
      self.accessibilityLabel = accessibilityLabel
      self.onSelected = onSelected
      self.customNode = nil
    }

    /// Creates a new custom bar button.
    public init(_ node: @escaping (UINavigationBarProps, UINavigationBarState) -> UINodeProtocol) {
      self.icon = UIImage()
      self.title = nil
      self.accessibilityLabel = nil
      self.onSelected = { }
      self.customNode = node
    }
  }

  /// The navigation bar title.
  /// - note: This property is going to be ignored if a custom *titleNode* is set for this
  /// navigation bar.
  public var title: String = ""
  /// Left bar button properties.
  public lazy var leftButtonItem: BarButtonItem = {
    return BarButtonItem(icon: makeDefaultBackButtonImage()) {
      guard let vc = UIGetTopmostViewController() else { return }
      if vc.isModal() {
        vc.dismiss(animated: true, completion: nil)
      } else {
        vc.navigationController?.popViewController(animated: true)
      }
    }
  }()
  /// *Optional* The right buttons in the navigation bar.
  public var rightButtonItems: [BarButtonItem] = []
  /// *Optional* Overrides the title component view.
  /// - note: When this property is set, the *title* property is ignored.
  public var titleNode: ((UINavigationBarProps, UINavigationBarState) -> UINodeProtocol)?
  /// A Boolean value indicating whether the title should be displayed in a large format.
  /// - note: This is currently not supported if your *TableViewController* has section headers.
  public var expandable: Bool = true
  /// The style applied to this navigation bar.
  public var style = UINavigationBarDefaultStyle.default
  /// Left for addtional properties that might be consumed by the subclasses.
  public var userInfo: Any?
  /// Cast the *userInfo* to the desired type.
  public func userInfo<T>(as: T.Type) -> T? {
    return userInfo as? T
  }
  /// The current scroll progress (0.0 to 1.0).
  public func scrollProgress(currentHeight: CGFloat) -> CGFloat {
    let height = currentHeight - style.heightWhenNormal
    return height/style.heightWhenNormal
  }

  /// Extracts the system back button image from a navigation bar.
  private func makeDefaultBackButtonImage() -> UIImage {
    let image = UIImage.yg_image(from: "←",
                                 color: style.tintColor,
                                 font: UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.bold),
                                 size: CGSize(width: 22, height: 26))
    return image
  }
}

// MARK: - UINavigationBarState

open class UINavigationBarState: UIStateProtocol {
  /// The current navigation bar height
  public var height: CGFloat = 0
  /// Whether the navigation bar is currently expanded or not.
  /// - note: 'false' if the navigation bar property *expandable* is 'false'.
  public var isExpanded: Bool = false
  /// *Internal only* The state has not yet been initialized.
  private var initialized: Bool = false

  public required init() { }

  /// Initialise this state accordingly to the navigation bar preferences.
  func initializeIfNecessary(props: UINavigationBarProps) {
    guard !initialized else { return }
    initialized = true
    height = props.expandable ? props.style.heightWhenExpanded : props.style.heightWhenNormal
    isExpanded = props.expandable
  }
}

// MARK: - UINavigationBarComponent

open class UINavigationBarComponent: UIComponent<UINavigationBarState, UINavigationBarProps> {
  // Internal reuse identifiers.
  private enum Id: String {
    case navigationBar, notch, buttonBar, leftBarButton, rightBarButton, title, titleLabel
  }

  open override var props: UINavigationBarProps {
    didSet {
      overrideStyle(props.style)
    }
  }
  /// Entrypoint to override in subclasses.
  open func overrideStyle(_ style: UINavigationBarDefaultStyle) { }

  open override func render(context: UIContextProtocol) -> UINodeProtocol {
    let props = self.props
    let state = self.state
    state.initializeIfNecessary(props: props)
    // The main navigation bar node.
    let node = UINode<UIView>(reuseIdentifier: Id.navigationBar.rawValue) { spec in
      spec.set(\UIView.yoga.width, spec.canvasSize.width)
      spec.set(\UIView.yoga.height, state.height)
      spec.set(\UIView.backgroundColor, props.style.backgroundColor)
    }
    // The status bar protection background.
    let statusBar = UINode<UIView>(reuseIdentifier: Id.notch.rawValue, create: {
      let view = UIView()
      view.backgroundColor = props.style.backgroundColor
      view.yoga.percent.width = 100%
      view.yoga.height = props.style.heightWhenNormal
      view.yoga.marginTop = -view.yoga.height
      return view
    })
    // The overall navigation bar hierarchy.
    return node.children([
      statusBar,
      renderTitle(),
      renderBarButton(),
    ])
  }

  /// Renders the bar button view.
  /// - note: Override this method if you wish to render your navigation bar buttons differently.
  open func renderBarButton() -> UINodeProtocol {
    let props = self.props
    let state = self.state
    // Default margin unit (all of the margins are multiple of this, creating a grid-like layout).
    let unit: CGFloat = 4
    // Build the button bar.
    func makeBar() -> UIView {
      let view = UIView()
      view.backgroundColor = .clear
      view.yoga.position = .absolute
      view.yoga.height = props.style.heightWhenNormal
      view.yoga.marginTop = 0
      view.yoga.percent.width = 100%
      view.yoga.flexDirection = .row
      view.yoga.justifyContent = .spaceBetween
      view.yoga.alignItems = .center
      return view
    }
    // Build the left bar button item.
    func makeLeftButton() -> UIButton {
      let button = UIButton(type: .custom)
      button.setImage(props.leftButtonItem.icon, for: .normal)
      button.accessibilityLabel = props.leftButtonItem.accessibilityLabel
      button.yoga.width = props.style.heightWhenNormal
      button.yoga.percent.height = 100%
      button.onTap { _ in
        props.leftButtonItem.onSelected()
      }
      return button
    }
    /// Build a right bar button item.
    func makeRightButton() -> UIButton {
      let button = UIButton(type: .custom)
      button.yoga.minWidth = props.style.heightWhenNormal
      button.yoga.percent.height = 100%
      button.yoga.marginRight = unit * 4
      button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.regular)
      button.setTitleColor(props.style.tintColor, for: .normal)
      return button
    }
    // Left node.
    var left = props.leftButtonItem.customNode != nil ?
      props.leftButtonItem.customNode!(props, state) :
      UINode<UIView>(reuseIdentifier: Id.leftBarButton.rawValue, create: makeLeftButton)
    // The bar button item is skipped if 'disabled' is true.
    left = props.leftButtonItem.disabled ? UINilNode.nil : left
    // Right nodes.
    let items: [UINodeProtocol] = props.rightButtonItems.compactMap { item in
      // The bar button item is skipped if 'disabled' is true.
      if item.disabled { return nil }
      if let node = item.customNode { return node(props, state) }
      return UINode<UIButton>(reuseIdentifier: Id.rightBarButton.rawValue, create: makeRightButton){
        $0.view.onTap { _ in item.onSelected() }
        $0.view.setImage(item.icon, for: .normal)
        $0.view.accessibilityLabel = item.accessibilityLabel
        $0.view.setTitle(item.title, for: .normal)
      }
    }
    let right = UINode<UIView>().children(items)
    // Button bar node.
    let bar = UINode<UIView>(reuseIdentifier: Id.buttonBar.rawValue, create: makeBar)
    return bar.children([left, right])
  }

  /// Renders the title bar.
  /// - note: You can provide the *titleComponent* prop if you want a custom title view without
  ///  having to override this method
  open func renderTitle() -> UINodeProtocol {
    let props = self.props
    let state = self.state
    // Default margin unit (all of the margins are multiple of this, creating a grid-like layout).
    let unit: CGFloat = 4
    // Custom title component.
    if let titleNode = props.titleNode {
      return titleNode(props, state)
    }
    // Builds the title container view.
    func makeTitleContainer() -> UIView {
      let view = UIView()
      view.yoga.percent.width = 100%
      view.yoga.percent.height = 100%
      view.yoga.marginTop = 0
      view.yoga.paddingLeft = unit * 3
      view.yoga.paddingRight = view.yoga.paddingLeft
      view.yoga.justifyContent = .flexEnd
      view.yoga.alignItems = .center
      return view
    }
    // The title label changes its position and appearance according to the navigation bar
    // state.
    let title = UINode<UILabel>(reuseIdentifier: Id.titleLabel.rawValue) { spec in
      spec.set(\UILabel.yoga.percent.width, 100%)
      spec.set(\UILabel.text, props.title)
      spec.set(\UILabel.textColor, props.style.titleColor)
      if state.isExpanded {
        spec.set(\UILabel.font, props.style.expandedTitleFont)
        spec.set(\UILabel.yoga.marginTop, props.style.heightWhenNormal)
        spec.set(\UILabel.yoga.marginBottom, unit * 3)
        spec.set(\UILabel.yoga.height, CGFloat.undefined)
        spec.set(\UILabel.yoga.maxWidth, spec.canvasSize.width)
        spec.set(\UILabel.textAlignment, .left)
        let progress = props.scrollProgress(currentHeight: state.height)
        let alpha = pow(progress, 3)
        spec.set(\UILabel.alpha, min(1, alpha))
      } else {
        spec.set(\UILabel.font, props.style.titleFont)
        spec.set(\UILabel.yoga.marginTop, 0)
        spec.set(\UILabel.yoga.marginBottom, 0)
        spec.set(\UILabel.yoga.height, props.style.heightWhenNormal)
        spec.set(\UILabel.yoga.maxWidth, 0.5 * spec.canvasSize.width)
        spec.set(\UILabel.textAlignment, .center)
        spec.set(\UILabel.alpha, 1)
      }
    }
    let container = UINode<UIView>(reuseIdentifier: Id.title.rawValue, create: makeTitleContainer)
    return container.children([title])
  }

  /// Used to propagate the navigation bar style to its container.
  /// - note: Override this if you wish to change the navigation bar component container according
  /// to the current component state.
  open func updateNavigationBarContainer(_ view: UIView) {
    view.depthPreset = state.isExpanded ? props.style.depthWhenExpanded:props.style.depthWhenNormal
    view.backgroundColor = props.style.backgroundColor
  }
}

// MARK: - UINavigationBarManager

/// The container object for this navigation bar.
public final class UINavigationBarManager {
  /// The context that is going to be used to build the navigation bar component.
  private weak var context: UIContext?
  /// The custom navigation bar component.
  /// If you wish to use the component-based navigation bar in your ViewController, you simply have
  /// to assign your *UINavigationBarComponent* subclass to the manager's component. e.g.
  ///
  ///     navigationBarManager.component = context?.component(MyBarComponent.self, key: "navbar")
  ///
  /// You can use the default component by calling *makeDefaultNavigationBarComponent* e.g.
  ///
  ///     navigationBarManager.makeDefaultNavigationBarComponent()
  ///
  public var component: UINavigationBarComponent? = nil {
    didSet {
      component?.props = props
    }
  }
  /// The component-based navigation bar properties.
  /// You can then customize the navigation bar component by accessing to its 'props' e.g.
  ///
  ///     navigationBarManager.props.title = "Your title"
  ///     navigationBarManager.props.style.backgroundColor = .red
  ///
  public let props: UINavigationBarProps = UINavigationBarProps()
  /// The view that is going to be used to mount the *navigationBarComponent*.
  public lazy private(set) var view: UIView = makeNavigationBarView()
  /// The current navigation bar height (when the component-based navigation bar is enabled).
  public internal(set) var heightConstraint: NSLayoutConstraint?
  /// 'true' if the navigation bar component is enabled.
  public var hasCustomNavigationBar: Bool {
    return component != nil
  }
  /// Whether the navigation bar was hidden before pushing this ViewController.
  /// - note: *Internal only*.
  public internal(set) var wasNavigationBarHidden: Bool = false

  /// Builds the canvas view the navigation bar.
  private func makeNavigationBarView() -> UIView {
    let navBar = UIView()
    navBar.translatesAutoresizingMaskIntoConstraints = false
    return navBar
  }

  /// Constructs the default navigation bar.
  /// - note: The default navigation bar can be easily customised by accessing to its properties
  /// (see *UINavigationBarProps*) and its style (see *UINavigationBarDefaultStyle*).
  public func makeDefaultNavigationBarComponent() {
    component = context?.component(UINavigationBarComponent.self, key: "navigationBar")
    component?.props = props
  }

  /// Creates a new custom navigation bar manager with the given context.
  /// - parameter context: The context that is going to be used to build the bar component.
  public init(context: UIContext) {
    self.context = context
  }
}

// MARK: - UICustomNavigationBarProtocol

public protocol UICustomNavigationBarProtocol: UIScrollViewDelegate {
  /// The navigation bar manager associated with this *UIViewController*.
  var navigationBarManager: UINavigationBarManager { get }
}

/// Helper methods that coordinates the change of appearance in the custom navigation bar
/// component.
public extension UICustomNavigationBarProtocol where Self: UIViewController {
  /// Create and initalize the navigation bar (if necessary).
  /// - note: If *navigationBarManager.component* is not defined, this method is no-op.
  public func initializeNavigationBarIfNecessary() {
    let nv = navigationController
    navigationBarManager.wasNavigationBarHidden = nv?.isNavigationBarHidden ?? false
    // No custom navigation bar - nothing to do.
    guard let navigationBarComponent = navigationBarManager.component else { return }
    // Hides the system navigation bar.
    nv?.isNavigationBarHidden = true
    // Render the component-based one.
    navigationBarComponent.setCanvas(view: navigationBarManager.view,
                                     options: UIComponentCanvasOption.defaults())
    // No back button for the root view controller.
    if nv?.viewControllers.first === self {
      navigationBarComponent.props.leftButtonItem.disabled = true
    }
    renderNavigationBar()
  }

  /// Renders the navigation bar in its current state.
  /// - note: If *navigationBarManager.component* is not defined, this method is no-op.
  public func renderNavigationBar(updateHeightConstraint: Bool = true) {
    guard let navigationBarComponent = navigationBarManager.component else {
      navigationBarManager.heightConstraint?.constant = 0
      return
    }
    navigationBarComponent.setNeedsRender()
    navigationBarComponent.updateNavigationBarContainer(navigationBarManager.view)
    if updateHeightConstraint {
      navigationBarManager.heightConstraint?.constant = navigationBarComponent.state.height
    }
  }

  /// Tells the delegate when the user scrolls the content view within the receiver.
  /// - note: If *navigationBarManager.component* is not defined, this method is no-op.
  public func navigationBarDidScroll(_ scrollView: UIScrollView) {
    // There's no custom navigation bar component.
    guard let navigationBarComponent = navigationBarManager.component else { return }
    let y = scrollView.contentOffset.y
    let state = navigationBarComponent.state
    let props = navigationBarComponent.props

    // The navigation bar is not expandable, nothing to do.
    guard props.expandable else {
      renderNavigationBar(updateHeightConstraint: true)
      return
    }
    // Bounces the navigation bar.
    if y < 0 {
      state.height = props.style.heightWhenExpanded + (-y)
      scrollView.contentInset.top = 0
      renderNavigationBar(updateHeightConstraint: false)
      return
    }
    // Breaks when the scroll reaches the default navigation bar height.
    let offset = props.style.heightWhenExpanded - props.style.heightWhenNormal

    if y > offset {
      let wasExpanded = state.isExpanded
      state.isExpanded = false
      // Make sure that the height constraint is updated.
      if wasExpanded {
        state.height = props.style.heightWhenNormal
        scrollView.contentInset.top = offset
        renderNavigationBar(updateHeightConstraint: true)
      }
      state.height = props.style.heightWhenNormal
      renderNavigationBar(updateHeightConstraint: false)
    // Adjusts the height otherwise.
    } else {
      state.isExpanded = true
      state.height = props.style.heightWhenExpanded - y
      scrollView.contentInset.top = y
      renderNavigationBar(updateHeightConstraint: true)
    }
  }
}

// MARK: - UINavigationBarDefaultStyle

public struct UINavigationBarDefaultStyle {
  /// Default (system-like) appearance proxy for the component-based navigation bar.
  public static var `default` = UINavigationBarDefaultStyle()
  /// The expanded navigation bar height.
  /// - note: This is ignored whenever *expandable* is 'false'.
  public var heightWhenExpanded: CGFloat = 94
  /// The default navigation bar height.
  public var heightWhenNormal: CGFloat = 44
  /// The navigation bar background color.
  public var backgroundColor: UIColor = UIColor(displayP3Red:0.98, green: 0.98, blue: 0.98, alpha:1)
  /// The navigation bar title color.
  public var titleColor: UIColor = .black
  /// The font used when the navigation bar is *expandable*.
  public var expandedTitleFont: UIFont = UIFont.systemFont(ofSize: 30, weight: UIFont.Weight.black)
  /// The font used when the navigation bar is in its default mode.
  public var titleFont: UIFont = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold)
  /// The tint color applied to the navigation bar buttons (icons and text).
  public var tintColor: UIColor = UIColor(displayP3Red:0, green:0.47, blue:1, alpha:1)
  /// The font applied to the button items.
  public var buttonFont: UIFont = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.regular)
  /// The shadow applied when the navigation bar is expanded.
  public var depthWhenExpanded: DepthPreset = .none
  /// The shadow applied when the navigation bar is in its default mode.
  public var depthWhenNormal: DepthPreset = .depth2
}
