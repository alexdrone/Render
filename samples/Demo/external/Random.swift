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
    "The quick brown fox jumps over the lazy dog.",
    "Nulla quis sem at nibh elementum imperdiet.",
    "Duis sagittis ipsum.",
    "Praesent mauris.",
    "Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos.",
    "In scelerisque sem at dolor.",
    "Fusce ac turpis quis ligula lacinia aliquet.",
    "Nulla metus metus, ullamcorper vel, tincidunt sed, euismod in, nibh.",
    "Quisque volutpat condimentum velit.",
    "Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos.",
    "Nam nec ante.",
    "Sed lacinia, urna non tincidunt mattis, tortor neque adipiscing diam, a cursus ipsum ante quis turpis.",
    "Nulla facilisi.",
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
  ]
  return s[randomInt(0, max: s.count-1)]
}
