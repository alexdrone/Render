import UIKit

protocol UIPostRendering {
  /// content-size calculation for the scrollview should be applied after the layout.
  /// This is called after the scroll view is rendered.
  /// TableViews and CollectionViews are excluded from this post-render pass.
  func postRender()
}

extension UIScrollView: UIPostRendering {
  func postRender() {
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

// MARK: - Gesture recognizers

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

// MARK: - UIBezierPath
// Forked from louisdh/bezierpath-polygons.

extension UIBezierPath {

  private func addPointsAsRoundedPolygon(points: [CGPoint], cornerRadius: CGFloat) {
    lineCapStyle = .round
    usesEvenOddFillRule = true
    let len = points.count
    let prev = points[len - 1]
    let curr = points[0 % len]
    let next = points[1 % len]
    addPoint(prev: prev, curr: curr, next: next, cornerRadius: cornerRadius, first: true)
    for i in 0..<len {
      let p = points[i]
      let c = points[(i + 1) % len]
      let n = points[(i + 2) % len]
      addPoint(prev: p, curr: c, next: n, cornerRadius: cornerRadius, first: false)
    }
    close()
  }

  private func polygonPoints(sides: Int, x: CGFloat, y: CGFloat, radius: CGFloat) -> [CGPoint] {
    let angle = degreesToRadians(360 / CGFloat(sides))
    let cx = x // x origin
    let cy = y // y origin
    let r  = radius // radius of circle
    var i = 0
    var points = [CGPoint]()
    while i < sides {
      let xP = cx + r * cos(angle * CGFloat(i))
      let yP = cy + r * sin(angle * CGFloat(i))
      points.append(CGPoint(x: xP, y: yP))
      i += 1
    }
    return points
  }

  private func addPoint(prev: CGPoint,
                        curr: CGPoint,
                        next: CGPoint,
                        cornerRadius: CGFloat,
                        first: Bool) {
    // prev <- curr
    var c2p = CGPoint(x: prev.x - curr.x, y: prev.y - curr.y)
    // next <- curr
    var c2n = CGPoint(x: next.x - curr.x, y: next.y - curr.y)
    // normalize
    let magP = sqrt(c2p.x * c2p.x + c2p.y * c2p.y)
    let magN = sqrt(c2n.x * c2n.x + c2n.y * c2n.y)
    c2p.x /= magP
    c2p.y /= magP
    c2n.x /= magN
    c2n.y /= magN
    // angles
    let ω = acos(c2n.x * c2p.x + c2n.y * c2p.y)
    let θ = (.pi / 2) - (ω / 2)
    let adjustedCornerRadius = cornerRadius / θ * (.pi / 4)
    // r tan(θ)
    let rTanTheta = adjustedCornerRadius * tan(θ)
    var startPoint = CGPoint()
    startPoint.x = curr.x + rTanTheta * c2p.x
    startPoint.y = curr.y + rTanTheta * c2p.y
    var endPoint = CGPoint()
    endPoint.x = curr.x + rTanTheta * c2n.x
    endPoint.y = curr.y + rTanTheta * c2n.y
    if !first {
      // Go perpendicular from start point by corner radius
      var centerPoint = CGPoint()
      centerPoint.x = startPoint.x + c2p.y * adjustedCornerRadius
      centerPoint.y = startPoint.y - c2p.x * adjustedCornerRadius
      let startAngle = atan2(c2p.x, -c2p.y)
      let endAngle = startAngle + (2 * θ)
      addLine(to: startPoint)
      addArc(withCenter: centerPoint,
             radius: adjustedCornerRadius,
             startAngle: startAngle,
             endAngle: endAngle,
             clockwise: true)
    } else {
      move(to: endPoint)
    }
  }
}

public extension UIBezierPath {

  @objc public convenience init(roundedRegularPolygon rect: CGRect,
                                numberOfSides: Int,
                                cornerRadius: CGFloat) {
    guard numberOfSides > 2 else {
      self.init()
      return
    }
    self.init()
    let points = polygonPoints(sides: numberOfSides,
                               x: rect.width / 2,
                               y: rect.height / 2,
                               radius: min(rect.width, rect.height) / 2)
    self.addPointsAsRoundedPolygon(points: points, cornerRadius: cornerRadius)
  }
}

public extension UIBezierPath {

  @objc public func applyRotation(angle: CGFloat) {
    let bounds = self.cgPath.boundingBox
    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    let toOrigin = CGAffineTransform(translationX: -center.x, y: -center.y)
    self.apply(toOrigin)
    self.apply(CGAffineTransform(rotationAngle: degreesToRadians(angle)))
    let fromOrigin = CGAffineTransform(translationX: center.x, y: center.y)
    self.apply(fromOrigin)
  }

  @objc public func applyScale(scale: CGPoint) {
    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    let toOrigin = CGAffineTransform(translationX: -center.x, y: -center.y)
    apply(toOrigin)
    apply(CGAffineTransform(scaleX: scale.x, y: scale.y))
    let fromOrigin = CGAffineTransform(translationX: center.x, y: center.y)
    apply(fromOrigin)
  }
}

public func degreesToRadians(_ value: Double) -> CGFloat {
  return CGFloat(value * .pi / 180.0)
}

public func degreesToRadians(_ value: CGFloat) -> CGFloat {
  return degreesToRadians(Double(value))
}

public func radiansToDegrees(_ value: Double) -> CGFloat {
  return CGFloat((180.0 / .pi) * value)
}

public func radiansToDegrees(_ value: CGFloat) -> CGFloat {
  return radiansToDegrees(Double(value))
}

@objc @IBDesignable public class UIPolygonView: UIView {

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  private func commonInit() {
    backgroundColor = .clear
    frame.size.width = HeightPreset.medium.cgFloatValue
    frame.size.height = HeightPreset.medium.cgFloatValue
    cornerRadius = CornerRadiusPreset.cornerRadius1.cgFloatValue
  }

  @objc @IBInspectable public var rotation: CGFloat = 0.0 {
    didSet { self.setNeedsDisplay() }
  }
  @objc @IBInspectable public var foregroundColor: UIColor = .black {
    didSet { self.setNeedsDisplay() }
  }
  @objc @IBInspectable public var scale: CGPoint = CGPoint(x: 1, y: 1) {
    didSet { self.setNeedsDisplay() }
  }
  @objc @IBInspectable public var numberOfSides: Int = 6 {
    didSet { self.setNeedsDisplay() }
  }

  override public func draw(_ rect: CGRect) {
    let polygonPath = UIBezierPath(roundedRegularPolygon: rect,
                                   numberOfSides: numberOfSides,
                                   cornerRadius: cornerRadius)
    polygonPath.applyRotation(angle: rotation)
    polygonPath.applyScale(scale: scale)
    polygonPath.close()
    foregroundColor.setFill()
    polygonPath.fill()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    clipsToBounds = true
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
  case none
  case depth1
  case depth2
  case depth3
  case depth4
  case depth5
}

public struct Depth {
  /// Offset.
  public var offset: Offset
  /// Opacity.
  public var opacity: Float
  /// Radius.
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

@objc public enum MarginPreset: Int {
  case none = 0
  case tiny = 2
  case xsmall = 4
  case small = 8
  case `default` = 16
  case normal = 24
  case medium = 32
  case large = 40
  case xlarge = 48
  case xxlarge = 64

  public var cgFloatValue: CGFloat {
    return CGFloat(rawValue)
  }
}

@objc public enum HeightPreset: Int {
  case none = 0
  case tiny = 20
  case xsmall = 28
  case small = 36
  case `default` = 44
  case normal = 49
  case medium = 52
  case large = 60
  case xlarge = 68
  case xxlarge = 104

  public var cgFloatValue: CGFloat {
    return CGFloat(rawValue)
  }
}

@objc public enum CornerRadiusPreset: Int {
  case none
  case cornerRadius1
  case cornerRadius2
  case cornerRadius3
  case cornerRadius4
  case cornerRadius5
  case cornerRadius6
  case cornerRadius7
  case cornerRadius8
  case cornerRadius9

  public var cgFloatValue: CGFloat {
    return CornerRadiusPresetToValue(preset: self)
  }
}

@objc public enum BorderWidthPreset: Int {
  case none
  case border1
  case border2
  case border3
  case border4
  case border5
  case border6
  case border7
  case border8
  case border9

  /// A CGFloat representation of the border width preset.
  public var cgFloatValue: CGFloat {
    switch self {
    case .none: return 0
    case .border1: return 0.5
    case .border2: return 1
    case .border3: return 2
    case .border4: return 3
    case .border5: return 4
    case .border6: return 5
    case .border7: return 6
    case .border8: return 7
    case .border9: return 8
    }
  }
}

/// Converts the CornerRadiusPreset enum to a CGFloat value.
public func CornerRadiusPresetToValue(preset: CornerRadiusPreset) -> CGFloat {
  switch preset {
  case .none: return 0
  case .cornerRadius1: return 2
  case .cornerRadius2: return 4
  case .cornerRadius3: return 8
  case .cornerRadius4: return 12
  case .cornerRadius5: return 16
  case .cornerRadius6: return 20
  case .cornerRadius7: return 24
  case .cornerRadius8: return 28
  case .cornerRadius9: return 32
  }
}

@objc public enum ShapePreset: Int {
  case none
  case square
  case circle
}

fileprivate class ContainerLayer {
  /// A reference to the CALayer.
  fileprivate weak var layer: CALayer?
  /// A property that sets the height of the layer's frame.
  fileprivate var heightPreset = HeightPreset.default {
    didSet {
      layer?.height = CGFloat(heightPreset.rawValue)
    }
  }

  /// A property that sets the cornerRadius of the backing layer.
  fileprivate var cornerRadiusPreset = CornerRadiusPreset.none {
    didSet {
      layer?.cornerRadius = CornerRadiusPresetToValue(preset: cornerRadiusPreset)
    }
  }

  /// A preset property to set the borderWidth.
  fileprivate var borderWidthPreset = BorderWidthPreset.none {
    didSet {
      layer?.borderWidth = borderWidthPreset.cgFloatValue
    }
  }

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
  /// A property that accesses the frame.origin.x property.
  @IBInspectable open var x: CGFloat {
    get { return frame.origin.x }
    set(value) {
      frame.origin.x = value
      layoutShadowPath()
    }
  }
  /// A property that accesses the frame.origin.y property.
  @IBInspectable open var y: CGFloat {
    get { return frame.origin.y }
    set(value) {
      frame.origin.y = value
      layoutShadowPath()
    }
  }
  /// A property that accesses the frame.size.width property.
  @IBInspectable open var width: CGFloat {
    get { return frame.size.width }
    set(value) {
      frame.size.width = value
      if .none != shapePreset {
        frame.size.height = value
        layoutShape()
      }
      layoutShadowPath()
    }
  }
  /// A property that accesses the frame.size.height property.
  @IBInspectable open var height: CGFloat {
    get { return frame.size.height }
    set(value) {
      frame.size.height = value
      if .none != shapePreset {
        frame.size.width = value
        layoutShape()
      }
      layoutShadowPath()
    }
  }
  /// HeightPreset value.
  open var heightPreset: HeightPreset {
    get { return containerLayer.heightPreset }
    set(value) {
      containerLayer.heightPreset = value
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
  /// A property that sets the cornerRadius of the backing layer.
  open var cornerRadiusPreset: CornerRadiusPreset {
    get { return containerLayer.cornerRadiusPreset }
    set(value) {
      containerLayer.cornerRadiusPreset = value
    }
  }
  /// A preset property to set the borderWidth.
  open var borderWidthPreset: BorderWidthPreset {
    get { return containerLayer.borderWidthPreset }
    set(value) {
      containerLayer.borderWidthPreset = value
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
  /// HeightPreset value.
  @objc open var heightPreset: HeightPreset {
    get { return layer.heightPreset }
    set(value) { layer.heightPreset = value }
  }
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
  /// A property that sets the cornerRadius of the backing layer.
  @objc open var cornerRadiusPreset: CornerRadiusPreset {
    get { return layer.cornerRadiusPreset }
    set(value) {
      cornerRadius = cornerRadiusPreset.cgFloatValue
      layer.cornerRadiusPreset = value
    }
  }
  /// A preset property to set the borderWidth.
  @objc open var borderWidthPreset: BorderWidthPreset {
    get { return layer.borderWidthPreset }
    set(value) { layer.borderWidthPreset = value }
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

