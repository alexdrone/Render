import UIKit

// MARK: - UIScreenContext

public class UIScreenStateFactory {
  /// Default singletion screen state factory.
  static let `default` = UIScreenStateFactory()

  public enum Idiom: Int, Codable {
    /// Applicable for iPhone5, 5S, 5C and SE.
    case iPhoneSE
    /// Applicable for iPhone 6, 6S, 7 and 8.
    case iPhone8
    /// Applicable for iPhone 6+, 6S+, 7+ and 8+.
    case iPhone8Plus
    /// Applicable for iPhone X.
    case iPhoneX
    /// Any iPhone.
    case phone
    /// Applicable for any iPad.
    case iPad
    /// Applicable for Apple TV.
    case tv
    /// Any other unsupported interface idiom.
    case undefined

    /// The interface idiom for the current device screen.
    static func current() -> Idiom {
      let idiom = UIDevice().userInterfaceIdiom
      switch idiom {
      case .phone:
        switch UIScreen.main.nativeBounds.height {
        case 568: return .iPhoneSE
        case 667: return .iPhone8
        case 736: return .iPhone8Plus
        case 812: return .iPhoneX
        default: return .undefined
        }
      case .pad: return .iPad
      case .tv: return .tv
      default: return .undefined
      }
    }
  }

  public enum Orientation: Int, Codable {
    case portrait
    case landscape

    /// Queries the physical orientation of the device.
    static func current() -> Orientation {
      return isPortrait() ? .portrait : landscape
    }
    /// Returns 'true' if the phone is portrait, 'false' otherwise.
    private static func isPortrait() -> Bool {
      let orientation = UIDevice.current.orientation
      switch orientation {
      case .portrait, .portraitUpsideDown: return true
      case .faceUp:
        // Check the interface orientation
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        switch interfaceOrientation{
        case .portrait, .portraitUpsideDown: return true
        default: return false
        }
      default: return false
      }
    }
    /// Returns 'true' if the phone is landscape, 'false' otherwise.
    private static func isLandscape() -> Bool {
      return !isPortrait()
    }
  }

  public enum SizeClass: Int, Codable {
    case unspecified
    /// Indicates a regular size class.
    case regular
    /// Indicates a compact size class.
    case compact

    public static func horizontalSizeClass(for view: UIView? = nil) -> SizeClass {
      switch (view?.traitCollection ?? UIScreen.main.traitCollection).horizontalSizeClass {
      case .regular: return .regular
      case .compact: return .compact
      case .unspecified: return .unspecified
      }
    }

    public static func verticalSizeClass(for view: UIView? = nil) -> SizeClass {
      switch (view?.traitCollection ?? UIScreen.main.traitCollection).verticalSizeClass {
      case .regular: return .regular
      case .compact: return .compact
      case .unspecified: return .unspecified
      }
    }
  }

  public struct State: Codable {
    /// The user interface idiom based on the screen size.
    public let idiom: Idiom
    /// The physical orientation of the device.
    public let orientation: Orientation
    /// The horizontal size class of the trait collection.
    public let horizontalSizeClass: SizeClass
    /// The vertical size class of the trait collection.
    public let verticalSizeClass: SizeClass
    /// The width and the height of the physical screen.
    public let screenSize: CGSize
    /// The width and the height of the canvas view for this context.
    public let canvasSize: CGSize
    /// The width and the height for the size passed as argument for this last render pass.
    public let renderSize: CGSize
    /// The safe area of a view reflects the area not covered by navigation bars, tab bars,
    /// toolbars, and other ancestors that obscure a view controller's view.
    public let safeAreaSize: CGSize
    public let safeAreaInsets: Insets

    /// Edge inset values are applied to a rectangle to shrink or expand the area represented by
    /// that rectangle.
    public struct Insets: Codable {
      /// The inset on the top of an object.
      public let top: CGFloat
      /// The inset on the left of an object.
      public let left: CGFloat
      /// The inset on the bottom of an object.
      public let bottom: CGFloat
      /// The inset on the right of an object.
      public let right: CGFloat

      public var uiEdgeInsets: UIEdgeInsets {
        return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
      }

      public static func from(edgeInsets: UIEdgeInsets) -> Insets {
        return Insets(top: edgeInsets.top,
                      left: edgeInsets.left,
                      bottom: edgeInsets.bottom,
                      right: edgeInsets.right)
      }
    }
  }

  /// The canvas view in which the component will be rendered in.
  private var canvasViewProvider: () -> UIView?
  /// The width and the height for the size passed as argument for this last render pass.
  public var bounds: CGSize = UIScreen.main.nativeBounds.size

  init(canvasViewProvider: @escaping () -> UIView? = { nil }) {
    self.canvasViewProvider = canvasViewProvider
  }

  /// Returns the information about the screen at this very moment.
  public func state() -> State {
    let native = UIScreen.main.nativeBounds.size
    // Compute the Safe Area (if applicable).
    var safeAreaSize = native
    var safeAreaInsets = State.Insets(top: 0, left: 0, bottom: 0, right: 0)
    if #available(iOS 11.0, *) {
      let defaultView = UIApplication.shared.keyWindow?.rootViewController?.view
      if let view = canvasViewProvider() ?? defaultView {
        safeAreaInsets = State.Insets.from(edgeInsets: view.safeAreaInsets)
        safeAreaSize.width -= safeAreaInsets.left + safeAreaInsets.right
        safeAreaSize.height -= safeAreaInsets.top + safeAreaInsets.bottom
      }
    }
    return State(
      idiom: Idiom.current(),
      orientation: Orientation.current(),
      horizontalSizeClass: SizeClass.horizontalSizeClass(for: canvasViewProvider()),
      verticalSizeClass: SizeClass.verticalSizeClass(for: canvasViewProvider()),
      screenSize: native,
      canvasSize: canvasViewProvider()?.bounds.size ?? native,
      renderSize: bounds,
      safeAreaSize: safeAreaSize,
      safeAreaInsets: safeAreaInsets)
  }
}

// MARK: UIView

public extension UIView {
  /// Convenience method to install a component in a *UIView*.
  public func install(component: UIComponentProtocol, size: CGSize) -> UIView {
    let node = component.asNode()
    node.reconcile(in: self, size: size, options: [.preventDelegateCallbacks])
    if let subview = self.subviews.first {
      self.bounds.size = subview.bounds.size
    }
    return self
  }

  /// *Internal only* some of render transient configuration for this view.
  var renderContext: UIRenderConfigurationContainer {
    get {
      typealias C = UIRenderConfigurationContainer
      guard let obj = objc_getAssociatedObject(self, &_handleContext) as? C else {
          let container = C(view: self)
          objc_setAssociatedObject(self, &_handleContext, container, nonatomic)
          return container
      }
      return obj
    }
    set {
      objc_setAssociatedObject(self, &_handleContext, newValue, nonatomic)
    }
  }
  /// Whether this view has a node currently associated to it or not.
  public var hasNode: Bool {
    get {
      return (objc_getAssociatedObject(self, &_handleHasNode) as? NSNumber)?.boolValue ?? false
    }
    set {
      objc_setAssociatedObject(self, &_handleHasNode, NSNumber(value: newValue), nonatomic)
    }
  }

  /// Remove all of the registered targets if this view is a subclass of *UIControl*.
  func resetAllTargets() {
    if let control = self as? UIControl {
      for target in control.allTargets {
        control.removeTarget(target, action: nil, for: UIControl.Event.allEvents)
      }
    }
  }
}

// MARK: Geometry

public extension CGFloat {
  /// Used for flexible dimensions (*Yoga specific value*).
  public static let undefined: CGFloat = YGNaNSize.width
  /// An arbitrary large number to use for non-constrained layout.
  public static let max: CGFloat = 32768
  /// The positive difference between 1.0 and the next greater representable number.
  public static let epsilon: CGFloat = CGFloat(Float.ulpOfOne)
  /// Returns *0* if the number is NaN of inf.
  public var normal: CGFloat { return isNormal ? self : 0  }
}

public extension CGSize {
  /// Used for flexible dimensions (*Yoga specific value*).
  public static let undefined: CGSize = CGSize(width: CGFloat.undefined, height: CGFloat.undefined)
  /// An arbitrary large number to use for non-constrained layout.
  public static let max: CGSize =  CGSize(width: CGFloat.max, height: CGFloat.max)
  /// The positive difference between 1.0 and the next greater representable number.
  public static let epsilon: CGSize =  CGSize(width: CGFloat.epsilon, height: CGFloat.epsilon)
  /// CGSize equatable implementation.
  public static func ===(lhs: CGSize, rhs: CGSize) -> Bool {
    return  fabs(lhs.width - rhs.width) < CGFloat.epsilon
            && fabs(lhs.height - rhs.height) < CGFloat.epsilon
  }
}

public extension CGRect {
  /// Returns *0* if the number is NaN of inf.
  public mutating func normalize() {
    origin.x = origin.x.isNormal ? origin.x : 0
    origin.y = origin.y.isNormal ? origin.y : 0
    size.width = size.width.isNormal ? size.width : 0
    size.height = size.height.isNormal ? size.height : 0
  }
}

//MARK: - Private

private var _handleHasNode: UInt8 = 0
private var _handleContext: UInt8 = 0
private let nonatomic = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
