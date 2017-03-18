import UIKit
import Foundation

func randomInt(_ min: Int, max:Int) -> Int {
  return min + Int(arc4random_uniform(UInt32(max - min + 1)))
}

func randomChance() -> Bool {
  return  Int(arc4random_uniform(UInt32(10))) % 5 == 0
}

func randomString() -> String {

  let s = [
    "The quick brown fox jumps over the lazy dog",
    "Hallo!",
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut"
    + "labore et dolore magna aliqua.",
  ]
  return s[randomInt(0, max: s.count-1)]
}
