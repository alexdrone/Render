
import UIKit

public func snapshot(_ view: UIView) -> UIImage {
    view.layoutSubviews()
    UIGraphicsBeginImageContext(view.frame.size)
    view.layer.render(in: UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
}

extension UIColor {
    class public var A: UIColor {
        return UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1)
    }
    class public var B: UIColor {
        return UIColor(red: 0/255, green: 188/255, blue: 212/255, alpha: 1)
    }
    class public var C: UIColor {
        return UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1)
    }
    class public var D: UIColor {
        return UIColor(red: 165/255, green: 214/255, blue: 167/255, alpha: 1)
    }
    class public var E: UIColor {
        return UIColor(red: 46/255, green: 125/255, blue: 50/255, alpha: 1)
    }
    class public var F: UIColor {
        return UIColor(red: 244/255, green: 67/255, blue: 54/255, alpha: 1)
    }
    class public var G: UIColor {
        return UIColor(red: 33/255, green: 150/255, blue: 243/255, alpha: 1)
    }
}

public func randomString(_ length: Int) -> String {
    let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
    let allowedCharsCount = UInt32(allowedChars.characters.count)
    var randomString = ""
    for _ in (0..<length) {
        let randomNum = Int(arc4random_uniform(allowedCharsCount))
        let newCharacter = allowedChars[allowedChars.characters.index(allowedChars.startIndex, offsetBy: randomNum)]
        randomString += String(newCharacter)
    }
    return randomString
}

public func randomInt(_ min: Int, max:Int) -> Int {
    return min + Int(arc4random_uniform(UInt32(max - min + 1)))
}
