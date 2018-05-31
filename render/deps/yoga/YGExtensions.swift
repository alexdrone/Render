import UIKit
import ImageIO

// MARK: - YGPercentLayout Operator

postfix operator %

extension Int {
  public static postfix func %(value: Int) -> YGValue {
    return YGValue(value: Float(value), unit: .percent)
  }
}

extension Float {
  public static postfix func %(value: Float) -> YGValue {
    return YGValue(value: value, unit: .percent)
  }
}

extension CGFloat {
  public static postfix func %(value: CGFloat) -> YGValue {
    return YGValue(value: Float(value), unit: .percent)
  }
}

extension YGValue : ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
  public init(integerLiteral value: Int) {
    self = YGValue(value: Float(value), unit: .point)
  }

  public init(floatLiteral value: Float) {
    self = YGValue(value: value, unit: .point)
  }

  public init(_ value: Float) {
    self = YGValue(value: value, unit: .point)
  }

  public init(_ value: CGFloat) {
    self = YGValue(value: Float(value), unit: .point)
  }
}

public protocol UIPostRendering {
  /// content-size calculation for the scrollview should be applied after the layout.
  /// This is called after the scroll view is rendered.
  /// TableViews and CollectionViews are excluded from this post-render pass.
  func postRender()
}

extension UIScrollView: UIPostRendering {

  public func adjustContentSizeAfterComponentDidRender() {
    postRender()
  }

  public func postRender() {
    // Performs the change on the next runloop.
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0) {
      if let _ = self as? UITableView { return }
      if let _ = self as? UICollectionView { return }
      var x: CGFloat = 0
      var y: CGFloat = 0
      for subview in self.subviews {
        x = subview.frame.maxX > x ? subview.frame.maxX : x
        y = subview.frame.maxY > y ? subview.frame.maxY : y
      }
      if self.yoga.flexDirection == .column {
        self.contentSize = CGSize(width: self.contentSize.width, height: y)
      } else {
        self.contentSize = CGSize(width: x, height: self.contentSize.height)
      }
      self.isScrollEnabled = true
    }
  }
}

// MARK: - UIGestureRecognizer

class WeakGestureRecognizer: NSObject {
  weak var object: UIGestureRecognizer?
  var handler: ((UIGestureRecognizer) -> Void)? = nil

  @objc func handle(sender: UIGestureRecognizer) {
    handler?(sender)
  }
}

fileprivate var __handler: UInt8 = 0
extension UIView {

  /// All of the gesture recognizers registered through the closure based api.
  var gestureRecognizerProxyDictionary: NSMutableDictionary {
    get {
      if let obj = objc_getAssociatedObject(self, &__handler) as? NSMutableDictionary {
        return obj
      }
      let obj = NSMutableDictionary()
      objc_setAssociatedObject(self, &__handler, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return obj
    }
    set {
      objc_setAssociatedObject(self, &__handler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  /// Flush all of the existing gesture recognizers registered through the closure based api.
  public func flushGestureRecognizers() {
    guard let array = gestureRecognizerProxyDictionary.allValues as? [WeakGestureRecognizer] else {
      return
    }
    for obj in array {
      obj.handler = nil
      if let gesture = obj.object {
        gesture.removeTarget(nil, action: nil)
        gesture.view?.removeGestureRecognizer(gesture)
      }
      obj.object = nil
    }
    gestureRecognizerProxyDictionary = NSMutableDictionary()
  }

  /// Flush all of the existing gesture recognizers registered through the closure based api.
  public func flushGestureRecognizersRecursively() {
    flushGestureRecognizers()
    for subview in subviews {
      subview.flushGestureRecognizersRecursively()
    }
  }
}

public extension UIView {
  public func onGestureRecognizer<T: UIGestureRecognizer>(
    type: T.Type,
    key: NSString,
    numberOfTapsRequired: Int = 1,
    numberOfTouchesRequired: Int = 1,
    direction: UISwipeGestureRecognizerDirection = .down,
    _ handler: @escaping (UIGestureRecognizer) -> Void) {

    let wrapper = WeakGestureRecognizer()
    wrapper.handler = handler
    let selector = #selector(WeakGestureRecognizer.handle(sender:))
    let gesture = T(target: wrapper, action: selector)
    wrapper.object = gesture
    if let tapGesture = gesture as? UITapGestureRecognizer {
      tapGesture.numberOfTapsRequired = numberOfTapsRequired
      tapGesture.numberOfTouchesRequired = numberOfTouchesRequired
    }
    if let swipeGesture = gesture as? UISwipeGestureRecognizer {
      swipeGesture.direction = direction
    }
    // Safely remove the old gesture recognizer.
    if let old = gestureRecognizerProxyDictionary.object(forKey: key) as? WeakGestureRecognizer,
      let oldGesture = old.object {
      old.handler = nil
      old.object = nil
      oldGesture.removeTarget(nil, action: nil)
      oldGesture.view?.removeGestureRecognizer(oldGesture)
    }
    gestureRecognizerProxyDictionary.setObject(wrapper, forKey: key)
    addGestureRecognizer(gesture)
  }

  public func onTap(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UITapGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        handler)
  }

  public func onDoubleTap(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UITapGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        numberOfTapsRequired: 2,
                        handler)
  }

  public func onLongPress(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UILongPressGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        handler)
  }

  public func onSwipeLeft(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UISwipeGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        direction: .left,
                        handler)
  }

  public func onSwipeRight(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UISwipeGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        direction: .right,
                        handler)
  }

  public func onSwipeUp(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UISwipeGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        direction: .up,
                        handler)
  }

  public func onSwipeDown(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UISwipeGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        direction: .down,
                        handler)
  }

  public func onPan(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UIPanGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        handler)
  }

  public func onPinch(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UIPinchGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        handler)
  }

  public func onRotate(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UIRotationGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        handler)
  }

  public func onScreenEdgePan(_ handler: @escaping (UIGestureRecognizer) -> Void) {
    onGestureRecognizer(type: UIScreenEdgePanGestureRecognizer.self,
                        key: "\(#function)" as NSString,
                        handler)
  }
}

// MARK: - ContainerView
// Forked from CosmicMind/Material

public typealias Offset = UIOffset

extension CGSize {
  /// Returns an Offset version of the CGSize.
  public var asOffset: Offset {
    return Offset(size: self)
  }
}

extension Offset {
  public init(size: CGSize) {
    self.init(horizontal: size.width, vertical: size.height)
  }
}

extension Offset {
  /// Returns a CGSize version of the Offset.
  public var asSize: CGSize {
    return CGSize(width: horizontal, height: vertical)
  }
}

@objc public enum DepthPreset: Int {
  case none, depth1, depth2, depth3, depth4, depth5
}

public struct Depth {
  public var offset: Offset
  public var opacity: Float
  public var radius: CGFloat

  /// A tuple of raw values.
  public var rawValue: (CGSize, Float, CGFloat) {
    return (offset.asSize, opacity, radius)
  }

  /// Preset.
  public var preset = DepthPreset.none {
    didSet {
      let depth = DepthPresetToValue(preset: preset)
      offset = depth.offset
      opacity = depth.opacity
      radius = depth.radius
    }
  }

  public init(offset: Offset = .zero, opacity: Float = 0, radius: CGFloat = 0) {
    self.offset = offset
    self.opacity = opacity
    self.radius = radius
  }

   /// Initializer that takes in a DepthPreset.
   /// - Parameter preset: DepthPreset.
  public init(preset: DepthPreset) {
    self.init()
    self.preset = preset
  }

   /// Static constructor for Depth with values of 0.
   /// - Returns: A Depth struct with values of 0.
  static var zero: Depth {
    return Depth()
  }
}

/// Converts the DepthPreset enum to a Depth value.
public func DepthPresetToValue(preset: DepthPreset) -> Depth {
  switch preset {
  case .none:
    return .zero
  case .depth1:
    return Depth(offset: Offset(horizontal: 0, vertical: 0.5), opacity: 0.3, radius: 0.5)
  case .depth2:
    return Depth(offset: Offset(horizontal: 0, vertical: 1), opacity: 0.3, radius: 1)
  case .depth3:
    return Depth(offset: Offset(horizontal: 0, vertical: 2), opacity: 0.3, radius: 2)
  case .depth4:
    return Depth(offset: Offset(horizontal: 0, vertical: 4), opacity: 0.3, radius: 4)
  case .depth5:
    return Depth(offset: Offset(horizontal: 0, vertical: 8), opacity: 0.3, radius: 8)
  }
}

@objc public enum ShapePreset: Int {
  case none, square, circle
}

fileprivate class ContainerLayer {
  /// A reference to the CALayer.
  fileprivate weak var layer: CALayer?

  /// A preset property to set the shape.
  fileprivate var shapePreset = ShapePreset.none {
    didSet {
      layer?.layoutShape()
    }
  }
  /// A preset value for Depth.
  fileprivate var depthPreset: DepthPreset {
    get {
      return depth.preset
    }
    set(value) {
      depth.preset = value
    }
  }

  /// Grid reference.
  fileprivate var depth = Depth.zero {
    didSet {
      guard let v = layer else {
        return
      }
      v.shadowOffset = depth.offset.asSize
      v.shadowOpacity = depth.opacity
      v.shadowRadius = depth.radius
      v.layoutShadowPath()
    }
  }
  /// Enables automatic shadowPath sizing.
  fileprivate var isShadowPathAutoSizing = false

  fileprivate init(layer: CALayer?) {
    self.layer = layer
  }
}

private var _containerLayerKey: UInt8 = 0

extension CALayer {
  /// ContainerLayer Reference.
  fileprivate var containerLayer: ContainerLayer {
    get {
      typealias C = ContainerLayer
      let nonatomic = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
      guard let obj = objc_getAssociatedObject(self, &_containerLayerKey) as? C else {
        let container = ContainerLayer(layer: self)
        objc_setAssociatedObject(self, &_containerLayerKey, container, nonatomic)
        return container
      }
      return obj
    }
    set(value) {
      let nonatomic = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
      objc_setAssociatedObject(self, &_containerLayerKey, value, nonatomic)
    }
  }
  /// A property that manages the overall shape for the object. If either the
  /// width or height property is set, the other will be automatically adjusted
  /// to maintain the shape of the object.
  open var shapePreset: ShapePreset {
    get { return containerLayer.shapePreset }
    set(value) {
      containerLayer.shapePreset = value
    }
  }
  /// A preset value for Depth.
  open var depthPreset: DepthPreset {
    get { return depth.preset }
    set(value) {
      depth.preset = value
    }
  }
  /// Grid reference.
  open var depth: Depth {
    get { return containerLayer.depth }
    set(value) {
      containerLayer.depth = value
    }
  }
  /// Enables automatic shadowPath sizing.
  @IBInspectable open var isShadowPathAutoSizing: Bool {
    get { return containerLayer.isShadowPathAutoSizing }
    set(value) {
      containerLayer.isShadowPathAutoSizing = value
    }
  }
}

extension CALayer {
  /// Manages the layout for the shape of the view instance.
  open func layoutShape() {
    guard .none != shapePreset else { return }
    if 0 == bounds.width {
      bounds.size.width = bounds.height
    }
    if 0 == bounds.height {
      bounds.size.height = bounds.width
    }
    guard .circle == shapePreset else {
      cornerRadius = 0
      return
    }
    cornerRadius = bounds.size.width / 2
  }
  /// Sets the shadow path.
  open func layoutShadowPath() {
    guard isShadowPathAutoSizing else {
      return
    }
    if .none == depthPreset {
      shadowPath = nil
    } else {
      shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }
  }
}

extension UIView {
   /// A property that manages the overall shape for the object. If either the
   /// width or height property is set, the other will be automatically adjusted
   /// to maintain the shape of the object.
   @objc open var shapePreset: ShapePreset {
    get { return layer.shapePreset }
    set(value) { layer.shapePreset = value }
  }
  /// A preset value for Depth.
  @objc open var depthPreset: DepthPreset {
    get { return layer.depthPreset }
    set(value) { layer.depthPreset = value }
  }
  /// Depth reference.
  open var depth: Depth {
    get { return layer.depth }
    set(value) { layer.depth = value }
  }
  /// Enables automatic shadowPath sizing.
  @IBInspectable dynamic open var isShadowPathAutoSizing: Bool {
    get { return layer.isShadowPathAutoSizing }
    set(value) { layer.isShadowPathAutoSizing = value }
  }
}

extension UIView {
  /// Manages the layout for the shape of the view instance.
  internal func layoutShape() {
    layer.layoutShape()
  }
  /// Sets the shadow path.
  internal func layoutShadowPath() {
    layer.layoutShadowPath()
  }
  public func debugBoudingRect() {
    layer.borderColor = UIColor.red.cgColor
    layer.borderWidth = 2
  }
}

// MARK: UIColor Hex Format

public extension UIColor {
  convenience init?(hex: String) {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
    var rgb: UInt32 = 0
    var r: CGFloat = 0.0
    var g: CGFloat = 0.0
    var b: CGFloat = 0.0
    var a: CGFloat = 1.0
    let length = hexSanitized.count
    guard Scanner(string: hexSanitized).scanHexInt32(&rgb) else { return nil }
    if length == 6 {
      r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
      g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
      b = CGFloat(rgb & 0x0000FF) / 255.0

    } else if length == 8 {
      r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
      g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
      b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
      a = CGFloat(rgb & 0x000000FF) / 255.0
    } else {
      return nil
    }
    self.init(red: r, green: g, blue: b, alpha: a)
  }
}

public protocol UILayoutGuideProvider {
  var leadingAnchor: NSLayoutXAxisAnchor { get }
  var trailingAnchor: NSLayoutXAxisAnchor { get }
  var leftAnchor: NSLayoutXAxisAnchor { get }
  var rightAnchor: NSLayoutXAxisAnchor { get }
  var topAnchor: NSLayoutYAxisAnchor { get }
  var bottomAnchor: NSLayoutYAxisAnchor { get }
  var widthAnchor: NSLayoutDimension { get }
  var heightAnchor: NSLayoutDimension { get }
  var centerXAnchor: NSLayoutXAxisAnchor { get }
  var centerYAnchor: NSLayoutYAxisAnchor { get }
}

// MARK: UILayoutGuideProvider

extension UIView: UILayoutGuideProvider { }
extension UILayoutGuide: UILayoutGuideProvider { }

public extension UIView {
  public var compatibleSafeAreaLayoutGuide: UILayoutGuideProvider {
    if #available(iOS 11, *) {
      return safeAreaLayoutGuide
    } else {
      return self
    }
  }
}

// MARK: - UIStylesheetRepresentableEnum Yoga Compliancy

#if RENDER_MOD_STYLESHEET
extension YGAlign: UIStylesheetRepresentableEnum {
  public init?(rawValue: Int) { self.init(rawValue: Int32(rawValue)) }
  public static func expressionConstants() -> [String : Double] { return [:] }
}

extension YGDirection: UIStylesheetRepresentableEnum {
  public init?(rawValue: Int) { self.init(rawValue: Int32(rawValue)) }
  public static func expressionConstants() -> [String : Double] { return [:] }
}

extension YGFlexDirection: UIStylesheetRepresentableEnum {
  public init?(rawValue: Int) { self.init(rawValue: Int32(rawValue)) }
  public static func expressionConstants() -> [String : Double] { return [:] }
}

extension YGJustify: UIStylesheetRepresentableEnum {
  public init?(rawValue: Int) { self.init(rawValue: Int32(rawValue)) }
  public static func expressionConstants() -> [String : Double] { return [:] }
}

extension YGPositionType: UIStylesheetRepresentableEnum {
  public init?(rawValue: Int) { self.init(rawValue: Int32(rawValue)) }
  public static func expressionConstants() -> [String : Double] { return [:] }
}

extension YGWrap: UIStylesheetRepresentableEnum {
  public init?(rawValue: Int) { self.init(rawValue: Int32(rawValue)) }
  public static func expressionConstants() -> [String : Double] { return [:] }
}

extension YGOverflow: UIStylesheetRepresentableEnum {
  public init?(rawValue: Int) { self.init(rawValue: Int32(rawValue)) }
  public static func expressionConstants() -> [String : Double] { return [:] }
}

extension YGDisplay: UIStylesheetRepresentableEnum {
  public init?(rawValue: Int) { self.init(rawValue: Int32(rawValue)) }
  public static func expressionConstants() -> [String : Double] { return [:] }
}
#endif
