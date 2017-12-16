import XCTest
import UIKit
@testable import RenderNeutrino

class StylesheetTests: XCTestCase {

  func testCGFloat() {
    let parser = UIStylesheetParser()
    try! parser.parse(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "cgFloat")?.cgFloat
    XCTAssert(value == 42)
  }

  func testBool() {
    let parser = UIStylesheetParser()
    try! parser.parse(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "bool")?.bool
    XCTAssert(value == true)
  }

  func testInt() {
    let parser = UIStylesheetParser()
    try! parser.parse(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "integer")?.integer
    XCTAssert(value == 42)
  }

  func testCGFloatExpression() {
    let parser = UIStylesheetParser()
    try! parser.parse(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "cgFloatExpr")?.cgFloat
    XCTAssert(value == 42)
  }

  func testBoolExpression() {
    let parser = UIStylesheetParser()
    try! parser.parse(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "boolExpr")?.bool
    XCTAssert(value == true)
  }

  func testIntExpression() {
    let parser = UIStylesheetParser()
    try! parser.parse(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "integerExpr")?.integer
    XCTAssert(value == 42)
  }

  func testConstExpression() {
    let parser = UIStylesheetParser()
    try! parser.parse(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "const")?.cgFloat
    XCTAssert(value == 320)
  }

  func testColor() {
    let parser = UIStylesheetParser()
    try! parser.parse(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "color")?.color
    XCTAssert(value!.cgColor.components![0] == 1)
    XCTAssert(value!.cgColor.components![1] == 0)
    XCTAssert(value!.cgColor.components![2] == 0)
  }

  func testFont() {
    let parser = UIStylesheetParser()
    try! parser.parse(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "font")?.font
    XCTAssert(value!.pointSize == 42)
  }

  func testConditionalFloat() {
    let parser = UIStylesheetParser()
    try! parser.parse(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "conditionalFloat")?.cgFloat
    XCTAssert(value == 42)
  }

  func testConditionalFloatWithMultipleConditions() {
    let parser = UIStylesheetParser()
    try! parser.parse(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "multipleConditionalFloat")?.cgFloat
    XCTAssert(value == 42)
  }

  func testConditionalFloatWithMultipleExpressions() {
    let parser = UIStylesheetParser()
    try! parser.parse(yaml: standardDefs)
    let value = parser.rule(style: "Test", name: "multipleConditionalFloatWithExpr")?.cgFloat
    XCTAssert(value == 42)
  }
}


let standardDefs = """
Test:
  cgFloat: 42
  bool: true
  integer: 42
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


let example1 = """
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
