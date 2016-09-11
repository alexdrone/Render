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
  static func fromCEnum(cEnum: CEnumType) -> Self
}

//MARK: - Enums

public struct Directive {

  public enum Direction: Int {
    case Inherit
    case LTR
    case RTL
  }

  /// Establishes the main-axis, thus defining the direction flex items are placed
  /// in the flex container.
  public enum FlexDirection: Int {
    case Column
    case ColumnReverse
    case Row
    case RowReverse
  }

  /// It defines the alignment along the main axis.
  public enum Justify: Int {
    case FlexStart
    case Center
    case FlexEnd
    case SpaceBetween
    case SpaceAround
  }

  /// It makes possible to override the align-items value for specific flex items.
  public enum Align: Int {
    case Auto
    case FlexStart
    case Center
    case FlexEnd
    case Stretch
  }

  /// Wether is this position with absolute or relative spacing
  public enum PositionType: Int {
    case Relative
    case Absolute
  }

  /// Specifies whether flex items are forced into a single line or can be wrapped onto
  /// multiple lines.
  public enum WrapType: Int {
    case NoWrap
    case Wrap
  }

  /// - Note: left and top are shared between position[2] and position[4], so
  /// they have to be before right and bottom.
  public enum PositionIndex: Int {
    case Left
    case Top
    case Right
    case Bottom
    case Start
    case End
    case PositionCount
  }

  public enum DimensionIndex: Int {
    case Width
    case Height
  }
}

//MARK: - CEnumTransformable

extension Directive.Direction: CEnumTransformable {

  typealias CEnumType = css_direction_t

  static func defaultValue() -> Directive.Direction {
    return .Inherit
  }

  func toCEnum() -> css_direction_t {
    switch self {
    case .Inherit: return CSS_DIRECTION_INHERIT
    case .LTR: return CSS_DIRECTION_LTR
    case .RTL: return CSS_DIRECTION_RTL
    }
  }

  static func fromCEnum(cEnum: css_direction_t) -> Directive.Direction {
    switch cEnum {
    case CSS_DIRECTION_INHERIT: return .Inherit
    case CSS_DIRECTION_LTR: return .LTR
    case CSS_DIRECTION_RTL: return .RTL
    default: return Directive.Direction.defaultValue()
    }
  }
}

extension Directive.FlexDirection: CEnumTransformable {

  typealias CEnumType = css_flex_direction_t

  static func defaultValue() -> Directive.FlexDirection {
    return .Column
  }

  func toCEnum() -> css_flex_direction_t {
    switch self {
    case .Column: return CSS_FLEX_DIRECTION_COLUMN
    case .ColumnReverse: return CSS_FLEX_DIRECTION_COLUMN_REVERSE
    case .Row: return CSS_FLEX_DIRECTION_ROW
    case .RowReverse: return CSS_FLEX_DIRECTION_ROW_REVERSE
    }
  }

  static func fromCEnum(cEnum: css_flex_direction_t) -> Directive.FlexDirection {
    switch cEnum {
    case CSS_FLEX_DIRECTION_COLUMN: return .Column
    case CSS_FLEX_DIRECTION_COLUMN_REVERSE: return .ColumnReverse
    case CSS_FLEX_DIRECTION_ROW: return .Row
    case CSS_FLEX_DIRECTION_ROW_REVERSE: return .RowReverse
    default: return Directive.FlexDirection.defaultValue()
    }
  }
}

extension Directive.Justify: CEnumTransformable {

  typealias CEnumType = css_justify_t

  static func defaultValue() -> Directive.Justify {
    return .FlexStart
  }

  func toCEnum() -> css_justify_t {
    switch self {
    case .FlexStart: return CSS_JUSTIFY_FLEX_START
    case .Center: return CSS_JUSTIFY_CENTER
    case .FlexEnd: return CSS_JUSTIFY_FLEX_END
    case .SpaceBetween: return CSS_JUSTIFY_SPACE_BETWEEN
    case .SpaceAround: return CSS_JUSTIFY_SPACE_AROUND
    }
  }

  static func fromCEnum(cEnum: css_justify_t) -> Directive.Justify {
    switch cEnum {
    case CSS_JUSTIFY_FLEX_START: return .FlexStart
    case CSS_JUSTIFY_CENTER: return .Center
    case CSS_JUSTIFY_FLEX_END: return .FlexEnd
    case CSS_JUSTIFY_SPACE_BETWEEN: return .SpaceBetween
    case CSS_JUSTIFY_SPACE_AROUND: return .SpaceAround
    default: return Directive.Justify.defaultValue()
    }
  }
}

extension Directive.Align: CEnumTransformable {

  typealias CEnumType = css_align_t

  static func defaultValue() -> Directive.Align {
    return .Auto
  }

  func toCEnum() -> css_align_t {
    switch self {
    case .Auto: return CSS_ALIGN_AUTO
    case .FlexStart: return CSS_ALIGN_FLEX_START
    case .Center: return CSS_ALIGN_CENTER
    case .FlexEnd: return CSS_ALIGN_FLEX_END
    case .Stretch: return CSS_ALIGN_STRETCH
    }
  }

  static func fromCEnum(cEnum: css_align_t) -> Directive.Align {
    switch cEnum {
    case CSS_ALIGN_AUTO: return .Auto
    case CSS_ALIGN_FLEX_START: return .FlexStart
    case CSS_ALIGN_CENTER: return .Center
    case CSS_ALIGN_FLEX_END: return .FlexEnd
    case CSS_ALIGN_STRETCH: return .Stretch
    default: return Directive.Align.defaultValue()
    }
  }
}

extension Directive.PositionType: CEnumTransformable {

  typealias CEnumType = css_position_type_t

  static func defaultValue() -> Directive.PositionType {
    return .Relative
  }

  func toCEnum() -> css_position_type_t {
    switch self {
    case .Relative: return CSS_POSITION_RELATIVE
    case .Absolute: return CSS_POSITION_ABSOLUTE
    }
  }

  static func fromCEnum(cEnum: css_position_type_t) -> Directive.PositionType {
    switch cEnum {
    case CSS_POSITION_RELATIVE: return .Relative
    case CSS_POSITION_ABSOLUTE: return .Absolute
    default: return Directive.PositionType.defaultValue()
    }
  }
}

extension Directive.WrapType: CEnumTransformable {

  typealias CEnumType = css_wrap_type_t

  static func defaultValue() -> Directive.WrapType {
    return .NoWrap
  }

  func toCEnum() -> css_wrap_type_t {
    switch self {
    case .NoWrap: return CSS_NOWRAP
    case .Wrap: return CSS_WRAP
    }
  }

  static func fromCEnum(cEnum: css_wrap_type_t) -> Directive.WrapType {
    switch cEnum {
    case CSS_NOWRAP: return .NoWrap
    case CSS_WRAP: return .Wrap
    default: return Directive.WrapType.defaultValue()
    }
  }
}

extension Directive.PositionIndex: CEnumTransformable {

  typealias CEnumType = css_position_t

  static func defaultValue() -> Directive.PositionIndex {
    return .Left
  }

  func toCEnum() -> css_position_t {
    switch self {
    case .Left: return CSS_LEFT
    case .Top: return CSS_TOP
    case .Right: return CSS_RIGHT
    case .Bottom: return CSS_BOTTOM
    case .Start: return CSS_START
    case .End: return CSS_END
    case .PositionCount: return CSS_POSITION_COUNT
    }
  }

  static func fromCEnum(cEnum: css_position_t) -> Directive.PositionIndex {
    switch cEnum {
    case CSS_LEFT: return .Left
    case CSS_TOP: return .Top
    case CSS_RIGHT: return .Right
    case CSS_BOTTOM: return .Bottom
    case CSS_START: return .Start
    case CSS_END: return .End
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
    return .Width
  }

  func toCEnum() -> css_dimension_t {
    switch self {
    case .Width: return CSS_WIDTH
    case .Height: return CSS_HEIGHT
    }
  }

  static func fromCEnum(cEnum: css_dimension_t) -> Directive.DimensionIndex {
    switch cEnum {
    case CSS_WIDTH: return .Width
    case CSS_HEIGHT: return .Height
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

public let Undefined = Float(CSS_NAN())

public struct Flex {
  public static let Max: Float = 0.99
  public static let Min: Float = 0.01
}

//MARK: Layout
public class Layout {

  private let node: Node
  public var target: css_layout_t {
    return node.target.layout
  }

  init(node: Node) {
    self.node = node
  }

  public var shouldUpdate: Bool {
    get { return target.should_update }
    set { node.target.layout.should_update = newValue }
  }

  public var direction: Directive.Direction {
    get { return Directive.Direction.fromCEnum(target.direction) }
    set { node.target.layout.direction = newValue.toCEnum() }
  }

  public var lastDirection: Directive.Direction {
    get { return Directive.Direction.fromCEnum(target.last_direction) }
    set { node.target.layout.last_direction = newValue.toCEnum() }
  }

  public var position: Position {
    get { return target.position }
    set { node.target.layout.position =  newValue }
  }

  public var dimension: Dimension {
    get { return target.dimensions }
    set { node.target.layout.dimensions = newValue }
  }

  public var lastRequestedDimensions: Dimension {
    get { return target.last_requested_dimensions }
    set { node.target.layout.last_requested_dimensions = newValue }
  }

  public var lastParentMaxWidth: Float {
    get { return target.last_parent_max_width }
    set { node.target.layout.last_parent_max_width = newValue }
  }

  public var lastParentMaxHeight: Float {
    get { return target.last_parent_max_height }
    set { node.target.layout.last_parent_max_height = newValue }
  }

  public var lastDimensions: Dimension {
    get { return target.last_dimensions }
    set { node.target.layout.last_dimensions = newValue }
  }

  public var lastPosition: Dimension {
    get { return target.last_position }
    set { node.target.layout.last_position = newValue }
  }

  public func reset() {
    position = (0,0,position.2,position.3)
    lastPosition = (0,0)
    dimension = (Undefined, Undefined)
  }
}


//MARK: Style
public class Style {

  private let node: Node
  public var target: css_style_t {
    return node.target.style
  }

  init(node: Node) {
    self.node = node
  }

  public var direction: Directive.Direction {
    get { return Directive.Direction.fromCEnum(target.direction) }
    set { node.target.style.direction = newValue.toCEnum() }
  }

  public var flexDirection: Directive.FlexDirection {
    get { return Directive.FlexDirection.fromCEnum(target.flex_direction) }
    set { node.target.style.flex_direction = newValue.toCEnum() }
  }

  public var justifyContent: Directive.Justify {
    get { return Directive.Justify.fromCEnum(target.justify_content) }
    set { node.target.style.justify_content = newValue.toCEnum() }
  }

  public var alignContent: Directive.Align {
    get { return Directive.Align.fromCEnum(target.align_content) }
    set { node.target.style.align_content = newValue.toCEnum() }
  }

  public var alignItems: Directive.Align {
    get { return Directive.Align.fromCEnum(target.align_items) }
    set { node.target.style.align_items = newValue.toCEnum() }
  }

  public var alignSelf: Directive.Align {
    get { return Directive.Align.fromCEnum(target.align_self) }
    set { node.target.style.align_self = newValue.toCEnum() }
  }

  public var positionType: Directive.PositionType {
    get { return Directive.PositionType.fromCEnum(target.position_type) }
    set { node.target.style.position_type = newValue.toCEnum() }
  }

  public var flexWrap: Directive.WrapType {
    get { return Directive.WrapType.fromCEnum(target.flex_wrap) }
    set { node.target.style.flex_wrap = newValue.toCEnum() }
  }

  public var flex: Float {
    get { return target.flex }
    set { node.target.style.flex = newValue }
  }

  public var margin: Inset {
    get { return target.margin }
    set { node.target.style.margin = newValue }
  }

  public var position: Position {
    get { return target.position }
    set { node.target.style.position = newValue }
  }

  public var padding: Inset {
    get { return target.padding }
    set { node.target.style.padding = newValue }
  }

  public var border: Inset {
    get { return target.border }
    set { node.target.style.border = newValue }
  }

  public var dimensions: Dimension {
    get { return target.dimensions }
    set { node.target.style.dimensions = newValue }
  }

  public var minDimensions: Dimension {
    get { return target.minDimensions }
    set { node.target.style.minDimensions = newValue }
  }

  public var maxDimensions: Dimension {
    get { return target.maxDimensions }
    set { node.target.style.maxDimensions = newValue }
  }
}

public class Node {

  private var pointer = alloc_node()

  ///The measure callback for this item
  public var measure: ((node: Node, width: Float, height: Float) -> Dimension)?

  ///Returns the nth child for this node
  public var getChild: ((node: Node, index: Int) -> Node)?

  ///Wheter this node should be recalculated or not
  public var isDirty: ((node: Node) -> Bool)?

  ///Helper function to set the children
  public var children: [Node]? {
    didSet {
      childrenCount = self.children?.count ?? 0
      getChild = { return $0.children![$1] }
    }
  }

  public var target: css_node_t {
    get { return pointer.memory }
    set { pointer.memory = newValue }
  }

  lazy public var style: Style = { [unowned self] in
    return Style(node: self)
    }()

  lazy public var layout: Layout = { [unowned self] in
    return Layout(node: self)
    }()

  public init() {

    ///measure function wrapper
    let measureFunction: @convention(c) (UnsafeMutablePointer<Void>, Float, Float)
      -> css_dim_t = { (context, width, height) in

      let node = Unmanaged<Node>.fromOpaque(COpaquePointer(context)).takeUnretainedValue()
      if let callback = node.measure {
        let d = callback(node: node, width: width, height: height)
        return css_dim_t(dimensions: (d.width, d.height))
      }
      return css_dim_t(dimensions: (node.style.minDimensions.width,
                                    node.style.minDimensions.height))
    }

    ///get_child function wrapper
    let getChildFunction: @convention(c) (UnsafeMutablePointer<Void>, CInt)
      -> UnsafeMutablePointer<css_node_t> = { (context, idx) in

      let node = Unmanaged<Node>.fromOpaque(COpaquePointer(context)).takeUnretainedValue()
      if let callback = node.getChild {
        let n = callback(node: node, index: Int(idx))
        assert(n.pointer != nil)
        return n.pointer
      }
      return nil
    }

    ///is_dirty function wrapper
    let isDirtyFunction: @convention(c) (UnsafeMutablePointer<Void>) -> Bool = { (context) in
      let node = Unmanaged<Node>.fromOpaque(COpaquePointer(context)).takeUnretainedValue()
      if let callback = node.isDirty {
        return callback(node: node)
      }
      return true
    }

    init_css_node(pointer)
    target.measure = measureFunction
    target.get_child = getChildFunction
    target.is_dirty = isDirtyFunction
    target.context = UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque())

    self.reset()
  }

  ///Applies to defaults value to this node
  public func reset() {
    childrenCount = 0
    lineIndex = 0
    style.alignItems = .Stretch
    style.alignSelf = .Auto
    style.alignContent = .Center
    style.justifyContent = .FlexStart
    style.flexWrap = .NoWrap
    style.flexDirection = .Column
    style.positionType = .Relative
    style.maxDimensions = (FLT_MAX, FLT_MAX)
    style.minDimensions = (0, 0)
    style.dimensions = (Undefined, Undefined)
    style.margin = (0, 0, 0, 0, 0, 0)
    style.padding = (0, 0, 0, 0, 0, 0)
    style.border = (0, 0, 0, 0, 0, 0)
    style.flex = 0
    self.layout.reset()
  }

  public func style(@noescape configure: (Style) -> Void) {
    configure(style)
  }

  ///Re-set the layout properties
  public func resetLayout() {
    self.layout.reset()
    for child in children ?? [Node]() { child.resetLayout() }
  }

  public convenience init(@noescape with: (Node) -> Void) {
    self.init()
    with(self)
  }

  deinit {
    free_css_node(pointer)
  }

  public var childrenCount: Int {
    get { return Int(target.children_count) }
    set { target.children_count = Int32(newValue) }
  }

  public var lineIndex: Int {
    get { return Int(target.line_index) }
    set { target.line_index = Int32(newValue) }
  }

  public func layout(maxWidth: Float = Undefined,
                     maxHeight: Float = Undefined,
                     parentDirection: Directive.Direction = .Inherit) {
    resetLayout()
    layoutNode(pointer, maxWidth, maxHeight, parentDirection.toCEnum())
  }

}

//MARK: Operators

public func Dim(width: Float, _ height: Float) -> Dimension {
  return (width, height)
}

public func +(left: Dimension, right: Dimension) -> Dimension {
  return (left.width + right.width, left.width + right.width)
}

public func -(left: Dimension, right: Dimension) -> Dimension {
  return (left.width - right.width, left.width - right.width)
}








