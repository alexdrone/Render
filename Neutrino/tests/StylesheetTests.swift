import XCTest
import UIKit
@testable import RenderNeutrino

class StylesheetTests: XCTestCase {

  func testCGFloat() {
    let parser = UIStylesheetManager()
    try! parser.load(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "cgFloat")?.cgFloat
    XCTAssert(value == 42)
  }

  func testBool() {
    let parser = UIStylesheetManager()
    try! parser.load(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "bool")?.bool
    XCTAssert(value == true)
  }

  func testInt() {
    let parser = UIStylesheetManager()
    try! parser.load(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "integer")?.integer
    XCTAssert(value == 42)
  }

  func testCGFloatExpression() {
    let parser = UIStylesheetManager()
    try! parser.load(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "cgFloatExpr")?.cgFloat
    XCTAssert(value == 42)
  }

  func testBoolExpression() {
    let parser = UIStylesheetManager()
    try! parser.load(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "boolExpr")?.bool
    XCTAssert(value == true)
  }

  func testIntExpression() {
    let parser = UIStylesheetManager()
    try! parser.load(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "integerExpr")?.integer
    XCTAssert(value == 42)
  }

  func testConstExpression() {
    let parser = UIStylesheetManager()
    try! parser.load(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "const")?.cgFloat
    XCTAssert(value == 320)
  }

  func testColor() {
    let parser = UIStylesheetManager()
    try! parser.load(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "color")?.color
    XCTAssert(value!.cgColor.components![0] == 1)
    XCTAssert(value!.cgColor.components![1] == 0)
    XCTAssert(value!.cgColor.components![2] == 0)
  }

  func testFont() {
    let parser = UIStylesheetManager()
    try! parser.load(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "font")?.font
    XCTAssert(value!.pointSize == 42)
  }

  func testConditionalFloat() {
    let parser = UIStylesheetManager()
    try! parser.load(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "conditionalFloat")?.cgFloat
    XCTAssert(value == 42)
  }

  func testConditionalFloatWithMultipleConditions() {
    let parser = UIStylesheetManager()
    try! parser.load(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "multipleConditionalFloat")?.cgFloat
    XCTAssert(value == 42)
  }

  func testConditionalFloatWithMultipleExpressions() {
    let parser = UIStylesheetManager()
    try! parser.load(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "multipleConditionalFloatWithExpr")?.cgFloat
    XCTAssert(value == 42)
  }

  func testEnum() {
    let parser = UIStylesheetManager()
    try! parser.load(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "enum")?.enum(NSTextAlignment.self)
    XCTAssert(value == .right)
  }

  func testAccessFromStylesheetEnum() {
    try! UIStylesheetManager.default.load(yaml: fooDefs)
    XCTAssert(FooStylesheet.bar.cgFloat == 42)
    XCTAssert(FooStylesheet.baz.cgFloat == 42)
    XCTAssert(FooStylesheet.bax.bool)
  }

  func testApplyStyleseetToView() {
    try! UIStylesheetManager.default.load(yaml: viewDefs)
    let view = UIView()
    ViewStylesheet.apply(to: view)
    let value = view.backgroundColor
    XCTAssert(value!.cgColor.components![0] == 1)
    XCTAssert(value!.cgColor.components![1] == 0)
    XCTAssert(value!.cgColor.components![2] == 0)
    XCTAssert(view.borderWidth == 1)
    XCTAssert(view.yoga.margin == 10)
    XCTAssert(view.yoga.flexDirection == .row)
  }

  func testRefValues() {
    let parser = UIStylesheetManager()
    try! parser.load(yaml: standardDefs)
    var value = parser.rule(style: "Test", name: "cgFloat")?.cgFloat
    XCTAssert(value == 42)
    value = parser.rule(style: "Test", name: "refValue")?.cgFloat
    XCTAssert(value == 42)
  }

}

let standardDefs = """
Test:
  cgFloat: &_cgFloat 42
  refValue: *_cgFloat
  bool: true
  integer: 42
  enum: ${NSTextAlignment.right}
  cgFloatExpr: ${41+1}
  boolExpr: ${1 == 1 && true}
  integerExpr: ${41+1}
  const: ${iPhoneSE.width}
  color: !!color(#ff0000)
  font: !!font(Arial,42)
  conditionalFloat:
    ${false}: 41
    ${default}: 42
  multipleConditionalFloat:
    ${false}: 41
    ${1 == 1}: 42
    ${default}: 1
  multipleConditionalFloatWithExpr:
    ${false}: 41
    ${1 == 1}: ${41+1}
    ${default}: 1
"""

enum FooStylesheet: String, UIStylesheet {
  static let name: String = "Foo"
  case bar
  case baz
  case bax
}

let fooDefs = """
Foo:
  bar: 42
  baz: ${41+1}
  bax: true
"""

enum ViewStylesheet: String, UIStylesheet {
  static let name: String = "View"
  case customNonApplicableProperty
}

let viewDefs = """
View:
  backgroundColor: !!color(#ff0000)
  borderWidth: 1
  flexDirection: ${row}
  margin: 10
  customNonApplicableProperty: 42
"""

let exampleDefs = """
Color:
  blue: &_color_blue !!color(00ff00)
  red: &_color_red
    ${horizontal == compact and idiom == phone}:  !!color(00ff00)
    ${default}: !!color(00ff00)

Typography:
  small: !!font(Helvetica,12)

AppStoreEntry: &_AppStoreEntry
  backgroundColor: *_color_blue
  margin: 10
  textAlignment: ${NSTextAlignmentCenter}
AppStoreEntry_Expanded:
  <<: *_AppStoreEntry
  backgroundColor: *_color_red

"""
