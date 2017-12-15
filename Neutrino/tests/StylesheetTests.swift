import XCTest
import UIKit
@testable import RenderNeutrino

class StylesheetTests: XCTestCase {

  func testParser() {
    let parser = UIStylesheetParser()
    try! parser.parse(yaml: example1)
    XCTAssert(parser.yaml != nil)
  }
}


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
