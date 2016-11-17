//
//  Layout.swift
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

import UIKit

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

@objc public enum Direction: Int {
  case inherit
  case ltr
  case rtl
}

/// Establishes the main-axis, thus defining the direction flex items are placed
/// in the flex container.
@objc public enum FlexDirection: Int {
  case column
  case columnReverse
  case row
  case rowReverse
}

/// It defines the alignment along the main axis.
@objc public enum Justify: Int {
  case flexStart
  case center
  case flexEnd
  case spaceBetween
  case spaceAround
}

/// It makes possible to override the align-items value for specific flex items.
@objc public enum Align: Int {
  case auto
  case flexStart
  case center
  case flexEnd
  case stretch
}

/// Wether is this position with absolute or relative spacing
@objc public enum PositionType: Int {
  case relative
  case absolute
}

/// Specifies whether flex items are forced into a single line or can be wrapped onto
/// multiple lines.
@objc public enum WrapType: Int {
  case noWrap
  case wrap
}

@objc public enum PositionIndex: Int {
  case left
  case top
  case right
  case bottom
  case start
  case end
  case horizontal
  case vertical
  case all
  case count
}

@objc public enum DimensionIndex: Int {
  case width
  case height
}

@objc public enum MeasureMode: Int {
  case undefined
  case exactly
  case atMost
  case count
}

@objc public enum Overflow: Int {
  case visible
  case hidden
}
//MARK: - CEnumTransformable

extension Direction: CEnumTransformable {

  typealias CEnumType = CSSDirection

  static func defaultValue() -> Direction {
    return .inherit
  }

  func toCEnum() -> CSSDirection {
    switch self {
    case .inherit: return CSSDirectionInherit
    case .ltr: return CSSDirectionLTR
    case .rtl: return CSSDirectionRTL
    }
  }

  static func fromCEnum(cEnum: CSSDirection) -> Direction {
    switch cEnum {
    case CSSDirectionInherit: return .inherit
    case CSSDirectionLTR: return .ltr
    case CSSDirectionRTL: return .rtl
    default: return Direction.defaultValue()
    }
  }
}

extension FlexDirection: CEnumTransformable {

  typealias CEnumType = CSSFlexDirection

  static func defaultValue() -> FlexDirection {
    return .column
  }

  func toCEnum() -> CSSFlexDirection {
    switch self {
    case .column: return CSSFlexDirectionColumn
    case .columnReverse: return CSSFlexDirectionColumnReverse
    case .row: return CSSFlexDirectionRow
    case .rowReverse: return CSSFlexDirectionRowReverse
    }
  }

  static func fromCEnum(cEnum: CSSFlexDirection) -> FlexDirection {
    switch cEnum {
    case CSSFlexDirectionColumn: return .column
    case CSSFlexDirectionColumnReverse: return .columnReverse
    case CSSFlexDirectionRow: return .row
    case CSSFlexDirectionRowReverse: return .rowReverse
    default: return FlexDirection.defaultValue()
    }
  }
}

extension Justify: CEnumTransformable {

  typealias CEnumType = CSSJustify

  static func defaultValue() -> Justify {
    return .flexStart
  }

  func toCEnum() -> CSSJustify {
    switch self {
    case .flexStart: return CSSJustifyFlexStart
    case .center: return CSSJustifyCenter
    case .flexEnd: return CSSJustifyFlexEnd
    case .spaceBetween: return CSSJustifySpaceBetween
    case .spaceAround: return CSSJustifySpaceAround
    }
  }

  static func fromCEnum(cEnum: CSSJustify) -> Justify {
    switch cEnum {
    case CSSJustifyFlexStart: return .flexStart
    case CSSJustifyCenter: return .center
    case CSSJustifyFlexEnd: return .flexEnd
    case CSSJustifySpaceBetween: return .spaceBetween
    case CSSJustifySpaceAround: return .spaceAround
    default: return Justify.defaultValue()
    }
  }
}

extension Align: CEnumTransformable {

  typealias CEnumType = CSSAlign

  static func defaultValue() -> Align {
    return .auto
  }

  func toCEnum() -> CSSAlign {
    switch self {
    case .auto: return CSSAlignAuto
    case .flexStart: return CSSAlignFlexStart
    case .center: return CSSAlignCenter
    case .flexEnd: return CSSAlignFlexEnd
    case .stretch: return CSSAlignStretch
    }
  }

  static func fromCEnum(cEnum: CSSAlign) -> Align {
    switch cEnum {
    case CSSAlignAuto: return .auto
    case CSSAlignFlexStart: return .flexStart
    case CSSAlignCenter: return .center
    case CSSAlignFlexEnd: return .flexEnd
    case CSSAlignStretch: return .stretch
    default: return Align.defaultValue()
    }
  }
}

extension PositionType: CEnumTransformable {

  typealias CEnumType = CSSPositionType

  static func defaultValue() -> PositionType {
    return .relative
  }

  func toCEnum() -> CSSPositionType {
    switch self {
    case .relative: return CSSPositionTypeRelative
    case .absolute: return CSSPositionTypeAbsolute
    }
  }

  static func fromCEnum(cEnum: CSSPositionType) -> PositionType {
    switch cEnum {
    case CSSPositionTypeRelative: return .relative
    case CSSPositionTypeAbsolute: return .absolute
    default: return PositionType.defaultValue()
    }
  }
}

extension WrapType: CEnumTransformable {

  typealias CEnumType = CSSWrapType

  static func defaultValue() -> WrapType {
    return .noWrap
  }

  func toCEnum() -> CSSWrapType {
    switch self {
    case .noWrap: return CSSWrapTypeNoWrap
    case .wrap: return CSSWrapTypeWrap
    }
  }

  static func fromCEnum(cEnum: CSSWrapType) -> WrapType {
    switch cEnum {
    case CSSWrapTypeNoWrap: return .noWrap
    case CSSWrapTypeWrap: return .wrap
    default: return WrapType.defaultValue()
    }
  }
}

extension PositionIndex: CEnumTransformable {

  typealias CEnumType = CSSEdge

  static func defaultValue() -> PositionIndex {
    return .left
  }

  func toCEnum() -> CSSEdge {
    switch self {
    case .left: return CSSEdgeLeft
    case .top: return CSSEdgeTop
    case .right: return CSSEdgeRight
    case .bottom: return CSSEdgeBottom
    case .start: return CSSEdgeStart
    case .end: return CSSEdgeEnd
    case .horizontal: return CSSEdgeHorizontal
    case .vertical: return CSSEdgeVertical
    case .all: return CSSEdgeAll
    case .count: return CSSEdgeCount
    }
  }

  static func fromCEnum(cEnum: CSSEdge) -> PositionIndex {
    switch cEnum {
    case CSSEdgeLeft: return .left
    case CSSEdgeTop: return .top
    case CSSEdgeRight: return .right
    case CSSEdgeBottom: return .bottom
    case CSSEdgeStart: return .start
    case CSSEdgeEnd: return .end
    case CSSEdgeHorizontal: return .horizontal
    case CSSEdgeVertical: return .vertical
    case CSSEdgeAll: return .all
    case CSSEdgeCount: return .count
    default: return PositionIndex.defaultValue()
    }
  }

  func toIndex() -> Int {
    return Int(self.toCEnum().rawValue)
  }
}

extension DimensionIndex: CEnumTransformable {

  typealias CEnumType = CSSDimension

  static func defaultValue() -> DimensionIndex {
    return .width
  }

  func toCEnum() -> CSSDimension {
    switch self {
    case .width: return CSSDimensionWidth
    case .height: return CSSDimensionHeight
    }
  }

  static func fromCEnum(cEnum: CSSDimension) -> DimensionIndex {
    switch cEnum {
    case CSSDimensionWidth: return .width
    case CSSDimensionHeight: return .height
    default: return DimensionIndex.defaultValue()
    }
  }

  func toIndex() -> Int {
    return Int(self.toCEnum().rawValue)
  }
}

extension MeasureMode: CEnumTransformable {

  typealias CEnumType = CSSMeasureMode

  static func defaultValue() -> MeasureMode {
    return .undefined
  }

  func toCEnum() -> CSSMeasureMode {
    switch self {
    case .undefined: return CSSMeasureModeUndefined
    case .exactly: return CSSMeasureModeExactly
    case .atMost: return CSSMeasureModeAtMost
    case .count: return CSSMeasureModeCount
    }
  }

  static func fromCEnum(cEnum: CSSMeasureMode) -> MeasureMode {
    switch cEnum {
    case CSSMeasureModeUndefined: return .undefined
    case CSSMeasureModeExactly: return .exactly
    case CSSMeasureModeAtMost: return .atMost
    case CSSMeasureModeCount: return .count
    default: return MeasureMode.defaultValue()
    }
  }

  func toIndex() -> Int {
    return Int(self.toCEnum().rawValue)
  }
}

extension Overflow: CEnumTransformable {

  typealias CEnumType = CSSOverflow

  static func defaultValue() -> Overflow {
    return .hidden
  }

  func toCEnum() -> CSSOverflow {
    switch self {
    case .hidden: return CSSOverflowHidden
    case .visible: return CSSOverflowVisible
    }
  }

  static func fromCEnum(cEnum: CSSOverflow) -> Overflow {
    switch cEnum {
    case CSSOverflowHidden: return .hidden
    case CSSOverflowVisible: return .visible
    default: return Overflow.defaultValue()
    }
  }

  func toIndex() -> Int {
    return Int(self.toCEnum().rawValue)
  }
}

public extension UIView {

  public dynamic var useFlexbox: Bool {
    get { return css_usesFlexbox }
    set { css_usesFlexbox = newValue }
  }

  public dynamic var layout_direction: Direction {
    get { return Direction.fromCEnum(cEnum: self.css_direction) }
    set { self.css_direction = newValue.toCEnum() }
  }

  public dynamic var layout_flexDirection: FlexDirection {
    get { return FlexDirection.fromCEnum(cEnum: self.css_flexDirection) }
    set { self.css_flexDirection = newValue.toCEnum() }
  }

  public dynamic var layout_justifyContent: Justify {
    get { return Justify.fromCEnum(cEnum: self.css_justifyContent) }
    set { self.css_justifyContent = newValue.toCEnum() }
  }

  public dynamic var layout_alignContent: Align {
    get { return Align.fromCEnum(cEnum: self.css_alignContent) }
    set { self.css_alignContent = newValue.toCEnum() }
  }

  public dynamic var layout_alignItems: Align {
    get { return Align.fromCEnum(cEnum: self.css_alignItems) }
    set { self.css_alignItems = newValue.toCEnum() }
  }

  public dynamic var layout_alignSelf: Align {
    get { return Align.fromCEnum(cEnum: self.css_alignSelf) }
    set { self.css_alignSelf = newValue.toCEnum() }
  }

  public dynamic var layout_positionType: PositionType {
    get { return PositionType.fromCEnum(cEnum: self.css_positionType) }
    set { self.css_positionType = newValue.toCEnum() }
  }

  public dynamic var layout_wrapType: WrapType {
    get { return WrapType.fromCEnum(cEnum: self.css_flexWrap) }
    set { self.css_flexWrap = newValue.toCEnum() }
  }

  public dynamic var layout_flexGrow: CGFloat {
    get { return self.css_flexGrow }
    set { self.css_flexGrow = newValue }
  }

  public dynamic var layout_flexShrink: CGFloat {
    get { return self.css_flexShrink }
    set { self.css_flexShrink = newValue }
  }

  public dynamic var layout_flexBasis: CGFloat {
    get { return self.css_flexBasis }
    set { self.css_flexBasis = newValue }
  }

  public dynamic var layout_width: CGFloat {
    get { return self.css_width }
    set { self.css_width = newValue }
  }

  public dynamic var layout_height: CGFloat {
    get { return self.css_height }
    set { self.css_height = newValue }
  }

  public dynamic var layout_minWidth: CGFloat {
    get { return self.css_minWidth }
    set { self.css_minWidth = newValue }
  }

  public dynamic var layout_minHeight: CGFloat {
    get { return self.css_minHeight }
    set { self.css_minHeight = newValue }
  }

  public dynamic var layout_maxWidth: CGFloat {
    get { return self.css_maxWidth }
    set { self.css_maxWidth = newValue }
  }

  public dynamic var layout_maxHeight: CGFloat {
    get { return self.css_maxHeight }
    set { self.css_maxHeight = newValue }
  }

  public dynamic var layout_positionTop: CGFloat {
    get { return css_position(for: CSSEdgeTop) }
    set { css_setPosition(newValue, for: CSSEdgeTop) }
  }

  public dynamic var layout_positionLeft: CGFloat {
    get { return css_position(for: CSSEdgeLeft) }
    set { css_setPosition(newValue, for: CSSEdgeLeft) }
  }

  public dynamic var layout_positionRight: CGFloat {
    get { return css_position(for: CSSEdgeRight) }
    set { css_setPosition(newValue, for: CSSEdgeRight) }
  }

  public dynamic var layout_positionBottom: CGFloat {
    get { return css_position(for: CSSEdgeBottom) }
    set { css_setPosition(newValue, for: CSSEdgeBottom) }
  }

  public dynamic var layout_marginAll: CGFloat {
    get { return css_margin(for: CSSEdgeAll) }
    set { css_setMargin(newValue, for: CSSEdgeAll) }
  }

  public dynamic var layout_marginTop: CGFloat {
    get { return css_margin(for: CSSEdgeTop) }
    set { css_setMargin(newValue, for: CSSEdgeTop) }
  }

  public dynamic var layout_marginLeft: CGFloat {
    get { return css_margin(for: CSSEdgeLeft) }
    set { css_setMargin(newValue, for: CSSEdgeLeft) }
  }

  public dynamic var layout_marginRight: CGFloat {
    get { return css_margin(for: CSSEdgeRight) }
    set { css_setMargin(newValue, for: CSSEdgeRight) }
  }

  public dynamic var layout_marginBottom: CGFloat {
    get { return css_margin(for: CSSEdgeBottom) }
    set { css_setMargin(newValue, for: CSSEdgeBottom) }
  }

  public dynamic var layout_paddingAll: CGFloat {
    get { return css_padding(for: CSSEdgeAll) }
    set { css_setPadding(newValue, for: CSSEdgeAll) }
  }

  public dynamic var layout_paddingTop: CGFloat {
    get { return css_padding(for: CSSEdgeTop) }
    set { css_setPadding(newValue, for: CSSEdgeTop) }
  }

  public dynamic var layout_paddingLeft: CGFloat {
    get { return css_padding(for: CSSEdgeLeft) }
    set { css_setPadding(newValue, for: CSSEdgeLeft) }
  }

  public dynamic var layout_paddingRight: CGFloat {
    get { return css_padding(for: CSSEdgeRight) }
    set { css_setPadding(newValue, for: CSSEdgeRight) }
  }

  public dynamic var layout_paddingBottom: CGFloat {
    get { return css_padding(for: CSSEdgeBottom) }
    set { css_setPadding(newValue, for: CSSEdgeBottom) }
  }

  /** Restore the node flex properties. */
  public dynamic func layout_reset() {
    self.css_reset()
  }

  /** Compute and apply the flexbox layout. */
  public dynamic func layout_apply() {
    self.css_applyLayout()
  }

  /** Asks the view to calculate and return the size that best fits the specified size. */
  public dynamic func layout_sizeThatFits(constrainedSize: CGSize) -> CGSize {
    return css_sizeThatFits(constrainedSize)
  }
}
