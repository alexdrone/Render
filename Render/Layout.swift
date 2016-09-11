//
//  Node.swift
//  Render
//
//  Created by Alex Usbergo on 03/03/16.
//
//  Copyright (c) 2016 Alex Usbergo.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

protocol CEnumTransformable {

  associatedtype CEnumType

  ///The default value for this enum
  static func defaultValue() -> Self

  ///Transform to a C enum
  func toCEnum() -> CEnumType

  ///Transform from a C enum
  static func fromCEnum(_ cEnum: CEnumType) -> Self
}

//MARK: - Enums

public struct Directive {

  public enum Direction: Int {
    case inherit
    case ltr
    case rtl
  }

  /// Establishes the main-axis, thus defining the direction flex items are placed
  /// in the flex container.
  public enum FlexDirection: Int {
    case column
    case columnReverse
    case row
    case rowReverse
  }

  /// It defines the alignment along the main axis.
  public enum Justify: Int {
    case flexStart
    case center
    case flexEnd
    case spaceBetween
    case spaceAround
  }

  /// It makes possible to override the align-items value for specific flex items.
  public enum Align: Int {
    case auto
    case flexStart
    case center
    case flexEnd
    case stretch
  }

  /// Wether is this position with absolute or relative spacing
  public enum PositionType: Int {
    case relative
    case absolute
  }

  /// Specifies whether flex items are forced into a single line or can be wrapped onto
  /// multiple lines.
  public enum WrapType: Int {
    case noWrap
    case wrap
  }

  /// - Note: left and top are shared between position[2] and position[4], so
  /// they have to be before right and bottom.
  public enum PositionIndex: Int {
    case left
    case top
    case right
    case bottom
    case start
    case end
    case positionCount
  }

  public enum DimensionIndex: Int {
    case width
    case height
  }
}

//MARK: - CEnumTransformable

extension Directive.Direction: CEnumTransformable {

  typealias CEnumType = css_direction_t

  static func defaultValue() -> Directive.Direction {
    return .inherit
  }

  func toCEnum() -> css_direction_t {
    switch self {
    case .inherit: return CSS_DIRECTION_INHERIT
    case .ltr: return CSS_DIRECTION_LTR
    case .rtl: return CSS_DIRECTION_RTL
    }
  }

  static func fromCEnum(_ cEnum: css_direction_t) -> Directive.Direction {
    switch cEnum {
    case CSS_DIRECTION_INHERIT: return .inherit
    case CSS_DIRECTION_LTR: return .ltr
    case CSS_DIRECTION_RTL: return .rtl
    default: return Directive.Direction.defaultValue()
    }
  }
}

extension Directive.FlexDirection: CEnumTransformable {

  typealias CEnumType = css_flex_direction_t

  static func defaultValue() -> Directive.FlexDirection {
    return .column
  }

  func toCEnum() -> css_flex_direction_t {
    switch self {
    case .column: return CSS_FLEX_DIRECTION_COLUMN
    case .columnReverse: return CSS_FLEX_DIRECTION_COLUMN_REVERSE
    case .row: return CSS_FLEX_DIRECTION_ROW
    case .rowReverse: return CSS_FLEX_DIRECTION_ROW_REVERSE
    }
  }

  static func fromCEnum(_ cEnum: css_flex_direction_t) -> Directive.FlexDirection {
    switch cEnum {
    case CSS_FLEX_DIRECTION_COLUMN: return .column
    case CSS_FLEX_DIRECTION_COLUMN_REVERSE: return .columnReverse
    case CSS_FLEX_DIRECTION_ROW: return .row
    case CSS_FLEX_DIRECTION_ROW_REVERSE: return .rowReverse
    default: return Directive.FlexDirection.defaultValue()
    }
  }
}

extension Directive.Justify: CEnumTransformable {

  typealias CEnumType = css_justify_t

  static func defaultValue() -> Directive.Justify {
    return .flexStart
  }

  func toCEnum() -> css_justify_t {
    switch self {
    case .flexStart: return CSS_JUSTIFY_FLEX_START
    case .center: return CSS_JUSTIFY_CENTER
    case .flexEnd: return CSS_JUSTIFY_FLEX_END
    case .spaceBetween: return CSS_JUSTIFY_SPACE_BETWEEN
    case .spaceAround: return CSS_JUSTIFY_SPACE_AROUND
    }
  }

  static func fromCEnum(_ cEnum: css_justify_t) -> Directive.Justify {
    switch cEnum {
    case CSS_JUSTIFY_FLEX_START: return .flexStart
    case CSS_JUSTIFY_CENTER: return .center
    case CSS_JUSTIFY_FLEX_END: return .flexEnd
    case CSS_JUSTIFY_SPACE_BETWEEN: return .spaceBetween
    case CSS_JUSTIFY_SPACE_AROUND: return .spaceAround
    default: return Directive.Justify.defaultValue()
    }
  }
}

extension Directive.Align: CEnumTransformable {

  typealias CEnumType = css_align_t

  static func defaultValue() -> Directive.Align {
    return .auto
  }

  func toCEnum() -> css_align_t {
    switch self {
    case .auto: return CSS_ALIGN_AUTO
    case .flexStart: return CSS_ALIGN_FLEX_START
    case .center: return CSS_ALIGN_CENTER
    case .flexEnd: return CSS_ALIGN_FLEX_END
    case .stretch: return CSS_ALIGN_STRETCH
    }
  }

  static func fromCEnum(_ cEnum: css_align_t) -> Directive.Align {
    switch cEnum {
    case CSS_ALIGN_AUTO: return .auto
    case CSS_ALIGN_FLEX_START: return .flexStart
    case CSS_ALIGN_CENTER: return .center
    case CSS_ALIGN_FLEX_END: return .flexEnd
    case CSS_ALIGN_STRETCH: return .stretch
    default: return Directive.Align.defaultValue()
    }
  }
}

extension Directive.PositionType: CEnumTransformable {

  typealias CEnumType = css_position_type_t

  static func defaultValue() -> Directive.PositionType {
    return .relative
  }

  func toCEnum() -> css_position_type_t {
    switch self {
    case .relative: return CSS_POSITION_RELATIVE
    case .absolute: return CSS_POSITION_ABSOLUTE
    }
  }

  static func fromCEnum(_ cEnum: css_position_type_t) -> Directive.PositionType {
    switch cEnum {
    case CSS_POSITION_RELATIVE: return .relative
    case CSS_POSITION_ABSOLUTE: return .absolute
    default: return Directive.PositionType.defaultValue()
    }
  }
}

extension Directive.WrapType: CEnumTransformable {

  typealias CEnumType = css_wrap_type_t

  static func defaultValue() -> Directive.WrapType {
    return .noWrap
  }

  func toCEnum() -> css_wrap_type_t {
    switch self {
    case .noWrap: return CSS_NOWRAP
    case .wrap: return CSS_WRAP
    }
  }

  static func fromCEnum(_ cEnum: css_wrap_type_t) -> Directive.WrapType {
    switch cEnum {
    case CSS_NOWRAP: return .noWrap
    case CSS_WRAP: return .wrap
    default: return Directive.WrapType.defaultValue()
    }
  }
}

extension Directive.PositionIndex: CEnumTransformable {

  typealias CEnumType = css_position_t

  static func defaultValue() -> Directive.PositionIndex {
    return .left
  }

  func toCEnum() -> css_position_t {
    switch self {
    case .left: return CSS_LEFT
    case .top: return CSS_TOP
    case .right: return CSS_RIGHT
    case .bottom: return CSS_BOTTOM
    case .start: return CSS_START
    case .end: return CSS_END
    case .positionCount: return CSS_POSITION_COUNT
    }
  }

  static func fromCEnum(_ cEnum: css_position_t) -> Directive.PositionIndex {
    switch cEnum {
    case CSS_LEFT: return .left
    case CSS_TOP: return .top
    case CSS_RIGHT: return .right
    case CSS_BOTTOM: return .bottom
    case CSS_START: return .start
    case CSS_END: return .end
    default: return Directive.PositionIndex.defaultValue()
    }
  }

  func toIndex() -> Int {
    return Int(self.toCEnum().rawValue)
  }
}

extension Directive.DimensionIndex: CEnumTransformable {

  typealias CEnumType = css_dimension_t

  static func defaultValue() -> Directive.DimensionIndex {
    return .width
  }

  func toCEnum() -> css_dimension_t {
    switch self {
    case .width: return CSS_WIDTH
    case .height: return CSS_HEIGHT
    }
  }

  static func fromCEnum(_ cEnum: css_dimension_t) -> Directive.DimensionIndex {
    switch cEnum {
    case CSS_WIDTH: return .width
    case CSS_HEIGHT: return .height
    default: return Directive.DimensionIndex.defaultValue()
    }
  }

  func toIndex() -> Int {
    return Int(self.toCEnum().rawValue)
  }
}

//MARK: -

public typealias Dimension = (width: Float, height: Float)
public typealias Inset =
  (left: Float, top: Float, right: Float, bottom: Float, start: Float, end: Float)
public typealias Position = (left: Float, top: Float, right: Float, bottom: Float)

public let Undefined = Float.nan

public struct Flex {
  public static let Max: Float = 0.99
  public static let Min: Float = 0.01
}

//MARK: Layout
open class Layout {

  fileprivate let node: Node
  open var target: css_layout_t {
    return node.target.layout
  }

  init(node: Node) {
    self.node = node
  }

  open var shouldUpdate: Bool {
    get { return target.should_update }
    set { node.target.layout.should_update = newValue }
  }

  open var direction: Directive.Direction {
    get { return Directive.Direction.fromCEnum(target.direction) }
    set { node.target.layout.direction = newValue.toCEnum() }
  }

  open var lastDirection: Directive.Direction {
    get { return Directive.Direction.fromCEnum(target.last_direction) }
    set { node.target.layout.last_direction = newValue.toCEnum() }
  }

  open var position: Position {
    get { return target.position }
    set { node.target.layout.position =  newValue }
  }

  open var dimension: Dimension {
    get { return target.dimensions }
    set { node.target.layout.dimensions = newValue }
  }

  open var lastRequestedDimensions: Dimension {
    get { return target.last_requested_dimensions }
    set { node.target.layout.last_requested_dimensions = newValue }
  }

  open var lastParentMaxWidth: Float {
    get { return target.last_parent_max_width }
    set { node.target.layout.last_parent_max_width = newValue }
  }

  open var lastParentMaxHeight: Float {
    get { return target.last_parent_max_height }
    set { node.target.layout.last_parent_max_height = newValue }
  }

  open var lastDimensions: Dimension {
    get { return target.last_dimensions }
    set { node.target.layout.last_dimensions = newValue }
  }

  open var lastPosition: Dimension {
    get { return target.last_position }
    set { node.target.layout.last_position = newValue }
  }

  open func reset() {
    position = (0,0,position.2,position.3)
    lastPosition = (0,0)
    dimension = (Undefined, Undefined)
  }
}


//MARK: Style
open class Style {

  fileprivate let node: Node
  open var target: css_style_t {
    return node.target.style
  }

  init(node: Node) {
    self.node = node
  }

  open var direction: Directive.Direction {
    get { return Directive.Direction.fromCEnum(target.direction) }
    set { node.target.style.direction = newValue.toCEnum() }
  }

  open var flexDirection: Directive.FlexDirection {
    get { return Directive.FlexDirection.fromCEnum(target.flex_direction) }
    set { node.target.style.flex_direction = newValue.toCEnum() }
  }

  open var justifyContent: Directive.Justify {
    get { return Directive.Justify.fromCEnum(target.justify_content) }
    set { node.target.style.justify_content = newValue.toCEnum() }
  }

  open var alignContent: Directive.Align {
    get { return Directive.Align.fromCEnum(target.align_content) }
    set { node.target.style.align_content = newValue.toCEnum() }
  }

  open var alignItems: Directive.Align {
    get { return Directive.Align.fromCEnum(target.align_items) }
    set { node.target.style.align_items = newValue.toCEnum() }
  }

  open var alignSelf: Directive.Align {
    get { return Directive.Align.fromCEnum(target.align_self) }
    set { node.target.style.align_self = newValue.toCEnum() }
  }

  open var positionType: Directive.PositionType {
    get { return Directive.PositionType.fromCEnum(target.position_type) }
    set { node.target.style.position_type = newValue.toCEnum() }
  }

  open var flexWrap: Directive.WrapType {
    get { return Directive.WrapType.fromCEnum(target.flex_wrap) }
    set { node.target.style.flex_wrap = newValue.toCEnum() }
  }

  open var flex: Float {
    get { return target.flex }
    set { node.target.style.flex = newValue }
  }

  open var margin: Inset {
    get { return target.margin }
    set { node.target.style.margin = newValue }
  }

  open var position: Position {
    get { return target.position }
    set { node.target.style.position = newValue }
  }

  open var padding: Inset {
    get { return target.padding }
    set { node.target.style.padding = newValue }
  }

  open var border: Inset {
    get { return target.border }
    set { node.target.style.border = newValue }
  }

  open var dimensions: Dimension {
    get { return target.dimensions }
    set { node.target.style.dimensions = newValue }
  }

  open var minDimensions: Dimension {
    get { return target.minDimensions }
    set { node.target.style.minDimensions = newValue }
  }

  open var maxDimensions: Dimension {
    get { return target.maxDimensions }
    set { node.target.style.maxDimensions = newValue }
  }
}

open class Node {

  fileprivate var pointer = alloc_node()

  ///The measure callback for this item
  open var measure: ((_ node: Node, _ width: Float, _ height: Float) -> Dimension)?

  ///Returns the nth child for this node
  open var getChild: ((_ node: Node, _ index: Int) -> Node)?

  ///Wheter this node should be recalculated or not
  open var isDirty: ((_ node: Node) -> Bool)?

  ///Helper function to set the children
  open var children: [Node]? {
    didSet {
      childrenCount = self.children?.count ?? 0
      getChild = { return $0.children![$1] }
    }
  }

  open var target: css_node_t {
    get { return pointer!.pointee }
    set { pointer?.pointee = newValue }
  }

  lazy open var style: Style = { [unowned self] in
    return Style(node: self)
    }()

  lazy open var layout: Layout = { [unowned self] in
    return Layout(node: self)
    }()

  public init() {

    ///measure function wrapper
    let measureFunction: @convention(c) (UnsafeMutableRawPointer?, Float, Float)
      -> css_dim_t = { (context, width, height) in

      let node = Unmanaged<Node>.fromOpaque(context!).takeUnretainedValue()

      if let callback = node.measure {
        let d = callback(node, width, height)
        return css_dim_t(dimensions: (d.width, d.height))
      }
      return css_dim_t(dimensions: (node.style.minDimensions.width,
                                    node.style.minDimensions.height))
    }

    ///get_child function wrapper
    let getChildFunction: @convention(c) (UnsafeMutableRawPointer?, CInt)
      -> UnsafeMutablePointer<css_node_t>? = { (context, idx) in

      let node = Unmanaged<Node>.fromOpaque(context!).takeUnretainedValue()
      if let callback = node.getChild {
        let n = callback(node, Int(idx))
        assert(n.pointer != nil)
        return n.pointer!
      }
      return nil
    }

    ///is_dirty function wrapper
    let isDirtyFunction: @convention(c) (UnsafeMutableRawPointer?) -> Bool = { (context) in
      let node = Unmanaged<Node>.fromOpaque(context!).takeUnretainedValue()
      if let callback = node.isDirty {
        return callback(node)
      }
      return true
    }

    init_css_node(pointer)
    target.measure = measureFunction
    target.get_child = getChildFunction
    target.is_dirty = isDirtyFunction
    target.context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

    self.reset()
  }

  ///Applies to defaults value to this node
  open func reset() {
    childrenCount = 0
    lineIndex = 0
    style.alignItems = .stretch
    style.alignSelf = .auto
    style.alignContent = .center
    style.justifyContent = .flexStart
    style.flexWrap = .noWrap
    style.flexDirection = .column
    style.positionType = .relative
    style.maxDimensions = (FLT_MAX, FLT_MAX)
    style.minDimensions = (0, 0)
    style.dimensions = (Undefined, Undefined)
    style.margin = (0, 0, 0, 0, 0, 0)
    style.padding = (0, 0, 0, 0, 0, 0)
    style.border = (0, 0, 0, 0, 0, 0)
    style.flex = 0
    self.layout.reset()
  }

  open func style(_ configure: (Style) -> Void) {
    configure(style)
  }

  ///Re-set the layout properties
  open func resetLayout() {
    self.layout.reset()
    for child in children ?? [Node]() { child.resetLayout() }
  }

  public convenience init(with: (Node) -> Void) {
    self.init()
    with(self)
  }

  deinit {
    free_css_node(pointer)
  }

  open var childrenCount: Int {
    get { return Int(target.children_count) }
    set { target.children_count = Int32(newValue) }
  }

  open var lineIndex: Int {
    get { return Int(target.line_index) }
    set { target.line_index = Int32(newValue) }
  }

  open func layout(_ maxWidth: Float = Undefined,
                     maxHeight: Float = Undefined,
                     parentDirection: Directive.Direction = .inherit) {
    resetLayout()
    layoutNode(pointer, maxWidth, maxHeight, parentDirection.toCEnum())
  }

}

//MARK: Operators

public func Dim(_ width: Float, _ height: Float) -> Dimension {
  return (width, height)
}

public func +(left: Dimension, right: Dimension) -> Dimension {
  return (left.width + right.width, left.width + right.width)
}

public func -(left: Dimension, right: Dimension) -> Dimension {
  return (left.width - right.width, left.width - right.width)
}








