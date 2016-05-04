//
//  Extensions.swift
//  FlexboxLayout
//
//  Created by Alex Usbergo on 30/03/16.
//  Copyright © 2016 Alex Usbergo. All rights reserved.
//

import UIKit

struct _Reset {
    
    private static let View = UIView()
    private static func resetView(view: UIView, proto: UIView = _Reset.View) {
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
        _Reset.resetTargets(view)
    }
    
    private static let Label = UILabel()
    private static func resetLabel(label: UILabel) {
        _Reset.resetView(label, proto: _Reset.Label)
        label.backgroundColor = _Reset.Label.backgroundColor
        label.font = _Reset.Label.font
        label.textColor = _Reset.Label.textColor
        label.textAlignment = _Reset.Label.textAlignment
        label.numberOfLines = _Reset.Label.numberOfLines
        label.text = _Reset.Label.text
        label.attributedText = _Reset.Label.attributedText
        label.shadowColor = _Reset.Label.shadowColor
        label.shadowOffset = _Reset.Label.shadowOffset
        label.lineBreakMode = _Reset.Label.lineBreakMode
        label.highlightedTextColor = _Reset.Label.highlightedTextColor
        label.highlighted = _Reset.Label.highlighted
        label.userInteractionEnabled = _Reset.Label.userInteractionEnabled
        label.enabled = _Reset.Label.enabled
        label.adjustsFontSizeToFitWidth = _Reset.Label.adjustsFontSizeToFitWidth
        label.baselineAdjustment = _Reset.Label.baselineAdjustment
        label.minimumScaleFactor = _Reset.Label.minimumScaleFactor
        if #available(iOS 9.0, *) {
            label.allowsDefaultTighteningForTruncation = _Reset.Label.allowsDefaultTighteningForTruncation
        } else {
            // Fallback on earlier versions
        }
        _Reset.resetTargets(label)
    }
    
    private static let TextField = UITextField()
    private static func resetTextField(textField: UITextField) {
        _Reset.resetView(textField, proto: _Reset.TextField)
        textField.backgroundColor = _Reset.TextField.backgroundColor
        textField.font = _Reset.TextField.font
        textField.textColor = _Reset.TextField.textColor
        textField.textAlignment = _Reset.TextField.textAlignment
        textField.text = _Reset.TextField.text
        textField.attributedText = _Reset.TextField.attributedText
        textField.highlighted = _Reset.Label.highlighted
        textField.userInteractionEnabled = _Reset.TextField.userInteractionEnabled
        textField.enabled = _Reset.TextField.enabled
        textField.adjustsFontSizeToFitWidth = _Reset.TextField.adjustsFontSizeToFitWidth
        textField.borderStyle = _Reset.TextField.borderStyle
        textField.defaultTextAttributes = _Reset.TextField.defaultTextAttributes
        textField.placeholder = _Reset.TextField.placeholder
        textField.attributedPlaceholder = _Reset.TextField.attributedPlaceholder
        textField.clearsOnBeginEditing = _Reset.TextField.clearsOnBeginEditing
        textField.minimumFontSize = _Reset.TextField.minimumFontSize
        textField.background = _Reset.TextField.background
        textField.disabledBackground = _Reset.TextField.disabledBackground
        textField.allowsEditingTextAttributes = _Reset.TextField.allowsEditingTextAttributes
        textField.typingAttributes = _Reset.TextField.typingAttributes
        textField.clearButtonMode = _Reset.TextField.clearButtonMode
        textField.leftView = _Reset.TextField.leftView
        textField.leftViewMode = _Reset.TextField.rightViewMode
        textField.rightView = _Reset.TextField.rightView
        textField.rightViewMode = _Reset.TextField.rightViewMode
        textField.inputView = _Reset.TextField.inputView
        textField.inputAccessoryView = _Reset.TextField.inputAccessoryView
        textField.clearsOnInsertion = _Reset.TextField.clearsOnInsertion
        textField.delegate = nil
        _Reset.resetTargets(textField)
    }
    
    private static let TextView = UITextView()
    private static func resetTextView(textView: UITextView) {
        _Reset.resetView(textView, proto: _Reset.TextView)
        textView.backgroundColor = _Reset.TextView.backgroundColor
        textView.font = _Reset.TextView.font
        textView.textColor = _Reset.TextView.textColor
        textView.textAlignment = _Reset.TextView.textAlignment
        textView.text = _Reset.TextView.text
        textView.attributedText = _Reset.TextView.attributedText
        textView.userInteractionEnabled = _Reset.TextView.userInteractionEnabled
        textView.allowsEditingTextAttributes = _Reset.TextView.allowsEditingTextAttributes
        textView.inputView = _Reset.TextView.inputView
        textView.inputAccessoryView = _Reset.TextView.inputAccessoryView
        textView.clearsOnInsertion = _Reset.TextView.clearsOnInsertion
        textView.selectable = _Reset.TextView.selectable
        textView.selectedRange = _Reset.TextView.selectedRange
        textView.editable = _Reset.TextView.editable
        textView.dataDetectorTypes = _Reset.TextView.dataDetectorTypes
        textView.allowsEditingTextAttributes = _Reset.TextView.allowsEditingTextAttributes
        textView.scrollEnabled = _Reset.TextView.scrollEnabled
        textView.delegate = nil
        _Reset.resetTargets(textView)
    }
    
    private static let Button = UIButton()
    private static func resetButton(button: UIButton) {
        _Reset.resetView(button, proto: Button)
        if let title = button.titleLabel { _Reset.resetLabel(title) }
        if let image = button.imageView { _Reset.resetImageView(image) }
        
        button.backgroundColor = _Reset.TextView.backgroundColor
        button.setTitle(_Reset.Button.titleForState(.Disabled), forState: .Disabled)
        if #available(iOS 9.0, *) {
            button.setTitle(_Reset.Button.titleForState(.Focused), forState: .Focused)
        } else {
            // Fallback on earlier versions
        }
        button.setTitle(_Reset.Button.titleForState(.Highlighted), forState: .Highlighted)
        button.setTitle(_Reset.Button.titleForState(.Normal), forState: .Normal)
        button.setTitle(_Reset.Button.titleForState(.Reserved), forState: .Reserved)
        button.setTitle(_Reset.Button.titleForState(.Selected), forState: .Selected)
        
        button.setTitleColor(_Reset.Button.titleColorForState(.Disabled), forState: .Disabled)
        if #available(iOS 9.0, *) {
            button.setTitleColor(_Reset.Button.titleColorForState(.Focused), forState: .Focused)
        } else {
            // Fallback on earlier versions
        }
        button.setTitleColor(_Reset.Button.titleColorForState(.Highlighted), forState: .Highlighted)
        button.setTitleColor(_Reset.Button.titleColorForState(.Normal), forState: .Normal)
        button.setTitleColor(_Reset.Button.titleColorForState(.Reserved), forState: .Reserved)
        button.setTitleColor(_Reset.Button.titleColorForState(.Selected), forState: .Selected)
        
        button.setTitleShadowColor(_Reset.Button.titleShadowColorForState(.Disabled), forState: .Disabled)
        if #available(iOS 9.0, *) {
            button.setTitleShadowColor(_Reset.Button.titleShadowColorForState(.Focused), forState: .Focused)
        } else {
            // Fallback on earlier versions
        }
        button.setTitleShadowColor(_Reset.Button.titleShadowColorForState(.Highlighted), forState: .Highlighted)
        button.setTitleShadowColor(_Reset.Button.titleShadowColorForState(.Normal), forState: .Normal)
        button.setTitleShadowColor(_Reset.Button.titleShadowColorForState(.Reserved), forState: .Reserved)
        button.setTitleShadowColor(_Reset.Button.titleShadowColorForState(.Selected), forState: .Selected)
        
        button.setImage(_Reset.Button.imageForState(.Disabled), forState: .Disabled)
        if #available(iOS 9.0, *) {
            button.setImage(_Reset.Button.imageForState(.Focused), forState: .Focused)
        } else {
            // Fallback on earlier versions
        }
        button.setImage(_Reset.Button.imageForState(.Highlighted), forState: .Highlighted)
        button.setImage(_Reset.Button.imageForState(.Normal), forState: .Normal)
        button.setImage(_Reset.Button.imageForState(.Reserved), forState: .Reserved)
        button.setImage(_Reset.Button.imageForState(.Selected), forState: .Selected)
        
        button.setBackgroundImage(_Reset.Button.backgroundImageForState(.Disabled), forState: .Disabled)
        if #available(iOS 9.0, *) {
            button.setBackgroundImage(_Reset.Button.backgroundImageForState(.Focused), forState: .Focused)
        } else {
            // Fallback on earlier versions
        }
        button.setBackgroundImage(_Reset.Button.backgroundImageForState(.Highlighted), forState: .Highlighted)
        button.setBackgroundImage(_Reset.Button.backgroundImageForState(.Normal), forState: .Normal)
        button.setBackgroundImage(_Reset.Button.backgroundImageForState(.Reserved), forState: .Reserved)
        button.setBackgroundImage(_Reset.Button.backgroundImageForState(.Selected), forState: .Selected)
        
        button.setAttributedTitle(_Reset.Button.attributedTitleForState(.Disabled), forState: .Disabled)
        if #available(iOS 9.0, *) {
            button.setAttributedTitle(_Reset.Button.attributedTitleForState(.Focused), forState: .Focused)
        } else {
            // Fallback on earlier versions
        }
        button.setAttributedTitle(_Reset.Button.attributedTitleForState(.Highlighted), forState: .Highlighted)
        button.setAttributedTitle(_Reset.Button.attributedTitleForState(.Normal), forState: .Normal)
        button.setAttributedTitle(_Reset.Button.attributedTitleForState(.Reserved), forState: .Reserved)
        button.setAttributedTitle(_Reset.Button.attributedTitleForState(.Selected), forState: .Selected)
        _Reset.resetTargets(button)
    }
    
    private static let ImageView = UIImageView()
    private static func resetImageView(imageView: UIImageView) {
        _Reset.resetView(imageView, proto: _Reset.ImageView)
        imageView.backgroundColor = _Reset.ImageView.backgroundColor
        imageView.image = _Reset.ImageView.image
        imageView.highlighted = _Reset.ImageView.highlighted
        imageView.highlightedImage = _Reset.ImageView.highlightedImage
        imageView.animationImages = _Reset.ImageView.animationImages
        imageView.highlightedAnimationImages = _Reset.ImageView.highlightedAnimationImages
        imageView.animationDuration = _Reset.ImageView.animationDuration
        imageView.animationRepeatCount = _Reset.ImageView.animationRepeatCount
        imageView.tintColor = _Reset.ImageView.tintColor
        _Reset.resetTargets(imageView)
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
    public func prepareForComponentReuse() {
        _Reset.resetView(self)
    }
}

extension UILabel {
    public override func prepareForComponentReuse() {
        _Reset.resetLabel(self)
    }
}

extension UITextField {
    public override func prepareForComponentReuse() {
        _Reset.resetTextField(self)
    }
}

extension UITextView {
    public override func prepareForComponentReuse() {
        _Reset.resetTextView(self)
    }
}

extension UIButton {
    public override func prepareForComponentReuse() {
        _Reset.resetButton(self)
    }
}

extension UIImageView {
    public override func prepareForComponentReuse() {
        _Reset.resetImageView(self)
    }
}

extension FlexboxView where Self: UIView {

    internal func postRender() {
        
        // content-size calculation for the scrollview should be applied after the layout
        // This is called after the scroll view is rendered.
        // TableViews and CollectionViews are excluded from this post-render pass
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
