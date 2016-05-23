
import UIKit

public func snapshot(view: UIView) -> UIImage {
    view.layoutSubviews()
    UIGraphicsBeginImageContext(view.frame.size)
    view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}
