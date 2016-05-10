//
//  Extensions.swift
//  FlexboxLayout
//
//  Created by Alex Usbergo on 30/03/16.
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

struct Reset {
    
    private static let View = UIView()
    private static func resetView(view: UIView, proto: UIView = Reset.View) {
        view.backgroundColor = proto.backgroundColor
        view.tintColor = proto.backgroundColor
        view.accessibilityIdentifier = nil
        view.alpha = proto.alpha
        view.hidden = proto.hidden
        view.maskView = proto.maskView
        view.accessibilityHint = proto.accessibilityHint
        view.accessibilityLabel = proto.accessibilityLabel
        view.accessibilityTraits = proto.accessibilityTraits
        view.userInteractionEnabled = proto.userInteractionEnabled
        view.layer.borderWidth = proto.layer.borderWidth
        view.layer.borderColor = proto.layer.borderColor
        view.layer.shadowPath = proto.layer.shadowPath
        view.layer.shadowColor = proto.layer.shadowColor
        view.layer.shadowOffset = proto.layer.shadowOffset
        view.layer.shadowRadius = proto.layer.shadowRadius
        view.layer.shadowOpacity = proto.layer.shadowOpacity
        view.layer.cornerRadius = proto.layer.cornerRadius
        view.layer.masksToBounds = proto.layer.masksToBounds
        Reset.resetTargets(view)
    }
    
    private static let Label = UILabel()
    private static func resetLabel(label: UILabel) {
        Reset.resetView(label, proto: Reset.Label)
        label.backgroundColor = Reset.Label.backgroundColor
        label.font = Reset.Label.font
        label.textColor = Reset.Label.textColor
        label.textAlignment = Reset.Label.textAlignment
        label.numberOfLines = Reset.Label.numberOfLines
        label.text = Reset.Label.text
        label.attributedText = Reset.Label.attributedText
        label.shadowColor = Reset.Label.shadowColor
        label.shadowOffset = Reset.Label.shadowOffset
        label.lineBreakMode = Reset.Label.lineBreakMode
        label.highlightedTextColor = Reset.Label.highlightedTextColor
        label.highlighted = Reset.Label.highlighted
        label.userInteractionEnabled = Reset.Label.userInteractionEnabled
        label.enabled = Reset.Label.enabled
        label.adjustsFontSizeToFitWidth = Reset.Label.adjustsFontSizeToFitWidth
        label.baselineAdjustment = Reset.Label.baselineAdjustment
        label.minimumScaleFactor = Reset.Label.minimumScaleFactor
        if #available(iOS 9.0, *) {
            label.allowsDefaultTighteningForTruncation = Reset.Label.allowsDefaultTighteningForTruncation
        } else {
            // Fallback on earlier versions
        }
        Reset.resetTargets(label)
    }
    
    private static let TextField = UITextField()
    private static func resetTextField(textField: UITextField) {
        Reset.resetView(textField, proto: Reset.TextField)
        textField.backgroundColor = Reset.TextField.backgroundColor
        textField.font = Reset.TextField.font
        textField.textColor = Reset.TextField.textColor
        textField.textAlignment = Reset.TextField.textAlignment
        textField.text = Reset.TextField.text
        textField.attributedText = Reset.TextField.attributedText
        textField.highlighted = Reset.Label.highlighted
        textField.userInteractionEnabled = Reset.TextField.userInteractionEnabled
        textField.enabled = Reset.TextField.enabled
        textField.adjustsFontSizeToFitWidth = Reset.TextField.adjustsFontSizeToFitWidth
        textField.borderStyle = Reset.TextField.borderStyle
        textField.defaultTextAttributes = Reset.TextField.defaultTextAttributes
        textField.placeholder = Reset.TextField.placeholder
        textField.attributedPlaceholder = Reset.TextField.attributedPlaceholder
        textField.clearsOnBeginEditing = Reset.TextField.clearsOnBeginEditing
        textField.minimumFontSize = Reset.TextField.minimumFontSize
        textField.background = Reset.TextField.background
        textField.disabledBackground = Reset.TextField.disabledBackground
        textField.allowsEditingTextAttributes = Reset.TextField.allowsEditingTextAttributes
        textField.typingAttributes = Reset.TextField.typingAttributes
        textField.clearButtonMode = Reset.TextField.clearButtonMode
        textField.leftView = Reset.TextField.leftView
        textField.leftViewMode = Reset.TextField.rightViewMode
        textField.rightView = Reset.TextField.rightView
        textField.rightViewMode = Reset.TextField.rightViewMode
        textField.inputView = Reset.TextField.inputView
        textField.inputAccessoryView = Reset.TextField.inputAccessoryView
        textField.clearsOnInsertion = Reset.TextField.clearsOnInsertion
        textField.delegate = nil
        Reset.resetTargets(textField)
    }
    
    private static let TextView = UITextView()
    private static func resetTextView(textView: UITextView) {
        Reset.resetView(textView, proto: Reset.TextView)
        textView.backgroundColor = Reset.TextView.backgroundColor
        textView.font = Reset.TextView.font
        textView.textColor = Reset.TextView.textColor
        textView.textAlignment = Reset.TextView.textAlignment
        textView.text = Reset.TextView.text
        textView.attributedText = Reset.TextView.attributedText
        textView.userInteractionEnabled = Reset.TextView.userInteractionEnabled
        textView.allowsEditingTextAttributes = Reset.TextView.allowsEditingTextAttributes
        textView.inputView = Reset.TextView.inputView
        textView.inputAccessoryView = Reset.TextView.inputAccessoryView
        textView.clearsOnInsertion = Reset.TextView.clearsOnInsertion
        textView.selectable = Reset.TextView.selectable
        textView.selectedRange = Reset.TextView.selectedRange
        textView.editable = Reset.TextView.editable
        textView.dataDetectorTypes = Reset.TextView.dataDetectorTypes
        textView.allowsEditingTextAttributes = Reset.TextView.allowsEditingTextAttributes
        textView.scrollEnabled = Reset.TextView.scrollEnabled
        textView.delegate = nil
        Reset.resetTargets(textView)
    }
    
    private static let Button = UIButton()
    private static func resetButton(button: UIButton) {
        Reset.resetView(button, proto: Button)
        if let title = button.titleLabel { Reset.resetLabel(title) }
        if let image = button.imageView { Reset.resetImageView(image) }
        
        button.backgroundColor = Reset.TextView.backgroundColor
        button.setTitle(Reset.Button.titleForState(.Disabled), forState: .Disabled)
        if #available(iOS 9.0, *) {
            button.setTitle(Reset.Button.titleForState(.Focused), forState: .Focused)
        } else {
            // Fallback on earlier versions
        }
        button.setTitle(Reset.Button.titleForState(.Highlighted), forState: .Highlighted)
        button.setTitle(Reset.Button.titleForState(.Normal), forState: .Normal)
        button.setTitle(Reset.Button.titleForState(.Reserved), forState: .Reserved)
        button.setTitle(Reset.Button.titleForState(.Selected), forState: .Selected)
        
        button.setTitleColor(Reset.Button.titleColorForState(.Disabled), forState: .Disabled)
        if #available(iOS 9.0, *) {
            button.setTitleColor(Reset.Button.titleColorForState(.Focused), forState: .Focused)
        } else {
            // Fallback on earlier versions
        }
        button.setTitleColor(Reset.Button.titleColorForState(.Highlighted), forState: .Highlighted)
        button.setTitleColor(Reset.Button.titleColorForState(.Normal), forState: .Normal)
        button.setTitleColor(Reset.Button.titleColorForState(.Reserved), forState: .Reserved)
        button.setTitleColor(Reset.Button.titleColorForState(.Selected), forState: .Selected)
        
        button.setTitleShadowColor(Reset.Button.titleShadowColorForState(.Disabled), forState: .Disabled)
        if #available(iOS 9.0, *) {
            button.setTitleShadowColor(Reset.Button.titleShadowColorForState(.Focused), forState: .Focused)
        } else {
            // Fallback on earlier versions
        }
        button.setTitleShadowColor(Reset.Button.titleShadowColorForState(.Highlighted), forState: .Highlighted)
        button.setTitleShadowColor(Reset.Button.titleShadowColorForState(.Normal), forState: .Normal)
        button.setTitleShadowColor(Reset.Button.titleShadowColorForState(.Reserved), forState: .Reserved)
        button.setTitleShadowColor(Reset.Button.titleShadowColorForState(.Selected), forState: .Selected)
        
        button.setImage(Reset.Button.imageForState(.Disabled), forState: .Disabled)
        if #available(iOS 9.0, *) {
            button.setImage(Reset.Button.imageForState(.Focused), forState: .Focused)
        } else {
            // Fallback on earlier versions
        }
        button.setImage(Reset.Button.imageForState(.Highlighted), forState: .Highlighted)
        button.setImage(Reset.Button.imageForState(.Normal), forState: .Normal)
        button.setImage(Reset.Button.imageForState(.Reserved), forState: .Reserved)
        button.setImage(Reset.Button.imageForState(.Selected), forState: .Selected)
        
        button.setBackgroundImage(Reset.Button.backgroundImageForState(.Disabled), forState: .Disabled)
        if #available(iOS 9.0, *) {
            button.setBackgroundImage(Reset.Button.backgroundImageForState(.Focused), forState: .Focused)
        } else {
            // Fallback on earlier versions
        }
        button.setBackgroundImage(Reset.Button.backgroundImageForState(.Highlighted), forState: .Highlighted)
        button.setBackgroundImage(Reset.Button.backgroundImageForState(.Normal), forState: .Normal)
        button.setBackgroundImage(Reset.Button.backgroundImageForState(.Reserved), forState: .Reserved)
        button.setBackgroundImage(Reset.Button.backgroundImageForState(.Selected), forState: .Selected)
        
        button.setAttributedTitle(Reset.Button.attributedTitleForState(.Disabled), forState: .Disabled)
        if #available(iOS 9.0, *) {
            button.setAttributedTitle(Reset.Button.attributedTitleForState(.Focused), forState: .Focused)
        } else {
            // Fallback on earlier versions
        }
        button.setAttributedTitle(Reset.Button.attributedTitleForState(.Highlighted), forState: .Highlighted)
        button.setAttributedTitle(Reset.Button.attributedTitleForState(.Normal), forState: .Normal)
        button.setAttributedTitle(Reset.Button.attributedTitleForState(.Reserved), forState: .Reserved)
        button.setAttributedTitle(Reset.Button.attributedTitleForState(.Selected), forState: .Selected)
        Reset.resetTargets(button)
    }
    
    private static let ImageView = UIImageView()
    private static func resetImageView(imageView: UIImageView) {
        Reset.resetView(imageView, proto: Reset.ImageView)
        imageView.backgroundColor = Reset.ImageView.backgroundColor
        imageView.image = Reset.ImageView.image
        imageView.highlighted = Reset.ImageView.highlighted
        imageView.highlightedImage = Reset.ImageView.highlightedImage
        imageView.animationImages = Reset.ImageView.animationImages
        imageView.highlightedAnimationImages = Reset.ImageView.highlightedAnimationImages
        imageView.animationDuration = Reset.ImageView.animationDuration
        imageView.animationRepeatCount = Reset.ImageView.animationRepeatCount
        imageView.tintColor = Reset.ImageView.tintColor
        Reset.resetTargets(imageView)
    }
    
    static func resetTargets(view: UIView?) {
        guard let view = view else { return }
        if let control = view as? UIControl {
            for target in control.allTargets() {
                control.removeTarget(target, action: nil, forControlEvents: .AllEvents)
            }
        }
        if let textField = view as? UITextField {
            textField.delegate = nil
        }
    }
}

extension UIView {
    func prepareForComponentReuse() {
        Reset.resetView(self)
    }
}

extension UILabel {
    override func prepareForComponentReuse() {
        Reset.resetLabel(self)
    }
}

extension UITextField {
    override func prepareForComponentReuse() {
        Reset.resetTextField(self)
    }
}

extension UITextView {
    override func prepareForComponentReuse() {
        Reset.resetTextView(self)
    }
}

extension UIButton {
    override func prepareForComponentReuse() {
        Reset.resetButton(self)
    }
}

extension UIImageView {
    override func prepareForComponentReuse() {
        Reset.resetImageView(self)
    }
}

extension FlexboxView where Self: UIView {

    /// content-size calculation for the scrollview should be applied after the layout
    /// This is called after the scroll view is rendered.
    /// TableViews and CollectionViews are excluded from this post-render pass
    func postRender() {
        if let scrollView = self as? UIScrollView {
            if let _ = self as? UITableView { return }
            if let _ = self as? UICollectionView { return }
            scrollView.postRender()
        }
    }
}

extension UIScrollView {

    private func postRender() {
        var x: CGFloat = 0
        var y: CGFloat = 0
        for subview in self.subviews {
            x = CGRectGetMaxX(subview.frame) > x ? CGRectGetMaxX(subview.frame) : x
            y = CGRectGetMaxY(subview.frame) > y ? CGRectGetMaxY(subview.frame) : y
        }
        self.contentSize = CGSize(width: x, height: y)
        self.scrollEnabled = true
    }
}
