//
//  Reset.swift
//  Render
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

  fileprivate static let View = UIView()
  fileprivate static func resetView(_ view: UIView, proto: UIView = Reset.View) {
    view.backgroundColor = proto.backgroundColor
    view.tintColor = proto.backgroundColor
    view.accessibilityIdentifier = nil
    view.alpha = proto.alpha
    view.isHidden = proto.isHidden
    view.mask = proto.mask
    view.accessibilityHint = proto.accessibilityHint
    view.accessibilityLabel = proto.accessibilityLabel
    view.accessibilityTraits = proto.accessibilityTraits
    view.isUserInteractionEnabled = proto.isUserInteractionEnabled
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
    Reset.resetCssView(view)
  }

  fileprivate static func resetCssView(_ view: UIView, proto: UIView = Reset.View) {
    proto.css_usesFlexbox = true
    view.css_usesFlexbox = true
    view.css_direction = proto.css_direction
    view.css_flexDirection = proto.css_flexDirection
    view.css_justifyContent = proto.css_justifyContent
    view.css_alignContent = proto.css_alignContent
    view.css_alignSelf = proto.css_alignSelf
    view.css_alignItems = proto.css_alignItems
    view.css_positionType = proto.css_positionType
    view.css_flexWrap = proto.css_flexWrap
    view.css_flexGrow = proto.css_flexGrow
    view.css_flexShrink = proto.css_flexShrink
    view.css_flexBasis = proto.css_flexBasis
    view.css_width = proto.css_width
    view.css_height = proto.css_height
    view.css_minHeight = proto.css_minHeight
    view.css_minWidth = proto.css_minWidth
    view.css_maxWidth = proto.css_maxWidth
    view.css_maxHeight = proto.css_maxHeight
  }

  fileprivate static let Label = UILabel()
  fileprivate static func resetLabel(_ label: UILabel) {
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
    label.isHighlighted = Reset.Label.isHighlighted
    label.isUserInteractionEnabled = Reset.Label.isUserInteractionEnabled
    label.isEnabled = Reset.Label.isEnabled
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

  fileprivate static let TextField = UITextField()
  fileprivate static func resetTextField(_ textField: UITextField) {
    Reset.resetView(textField, proto: Reset.TextField)
    textField.backgroundColor = Reset.TextField.backgroundColor
    textField.font = Reset.TextField.font
    textField.textColor = Reset.TextField.textColor
    textField.textAlignment = Reset.TextField.textAlignment
    textField.text = Reset.TextField.text
    textField.attributedText = Reset.TextField.attributedText
    textField.isHighlighted = Reset.Label.isHighlighted
    textField.isUserInteractionEnabled = Reset.TextField.isUserInteractionEnabled
    textField.isEnabled = Reset.TextField.isEnabled
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

  fileprivate static let TextView = UITextView()
  fileprivate static func resetTextView(_ textView: UITextView) {
    Reset.resetView(textView, proto: Reset.TextView)
    textView.backgroundColor = Reset.TextView.backgroundColor
    textView.font = Reset.TextView.font
    textView.textColor = Reset.TextView.textColor
    textView.textAlignment = Reset.TextView.textAlignment
    textView.text = Reset.TextView.text
    textView.attributedText = Reset.TextView.attributedText
    textView.isUserInteractionEnabled = Reset.TextView.isUserInteractionEnabled
    textView.allowsEditingTextAttributes = Reset.TextView.allowsEditingTextAttributes
    textView.inputView = Reset.TextView.inputView
    textView.inputAccessoryView = Reset.TextView.inputAccessoryView
    textView.clearsOnInsertion = Reset.TextView.clearsOnInsertion
    textView.isSelectable = Reset.TextView.isSelectable
    textView.selectedRange = Reset.TextView.selectedRange
    textView.isEditable = Reset.TextView.isEditable
    textView.dataDetectorTypes = Reset.TextView.dataDetectorTypes
    textView.allowsEditingTextAttributes = Reset.TextView.allowsEditingTextAttributes
    textView.isScrollEnabled = Reset.TextView.isScrollEnabled
    textView.delegate = nil
    Reset.resetTargets(textView)
  }

  fileprivate static let Button = UIButton()
  fileprivate static func resetButton(_ button: UIButton) {
    Reset.resetView(button, proto: Button)
    if let title = button.titleLabel { Reset.resetLabel(title) }
    if let image = button.imageView { Reset.resetImageView(image) }

    button.backgroundColor = Reset.TextView.backgroundColor
    button.setTitle(Reset.Button.title(for: .disabled), for: .disabled)
    if #available(iOS 9.0, *) {
      button.setTitle(Reset.Button.title(for: .focused), for: .focused)
    } else {
      // Fallback on earlier versions
    }
    button.setTitle(Reset.Button.title(for: .highlighted), for: .highlighted)
    button.setTitle(Reset.Button.title(for: UIControlState()), for: UIControlState())
    button.setTitle(Reset.Button.title(for: .reserved), for: .reserved)
    button.setTitle(Reset.Button.title(for: .selected), for: .selected)

    button.setTitleColor(Reset.Button.titleColor(for: .disabled),
                         for: .disabled)
    if #available(iOS 9.0, *) {
      button.setTitleColor(Reset.Button.titleColor(for: .focused),
                           for: .focused)
    } else {
      // Fallback on earlier versions
    }
    button.setTitleColor(Reset.Button.titleColor(for: .highlighted),
                         for: .highlighted)
    button.setTitleColor(Reset.Button.titleColor(for: UIControlState()),
                         for: UIControlState())
    button.setTitleColor(Reset.Button.titleColor(for: .reserved),
                         for: .reserved)
    button.setTitleColor(Reset.Button.titleColor(for: .selected),
                         for: .selected)

    button.setTitleShadowColor(Reset.Button.titleShadowColor(for: .disabled),
                               for: .disabled)
    if #available(iOS 9.0, *) {
      button.setTitleShadowColor(Reset.Button.titleShadowColor(for: .focused),
                                 for: .focused)
    } else {
      // Fallback on earlier versions
    }
    button.setTitleShadowColor(Reset.Button.titleShadowColor(for: .highlighted),
                               for: .highlighted)
    button.setTitleShadowColor(Reset.Button.titleShadowColor(for: UIControlState()),
                               for: UIControlState())
    button.setTitleShadowColor(Reset.Button.titleShadowColor(for: .reserved),
                               for: .reserved)
    button.setTitleShadowColor(Reset.Button.titleShadowColor(for: .selected),
                               for: .selected)

    button.setImage(Reset.Button.image(for: .disabled), for: .disabled)
    if #available(iOS 9.0, *) {
      button.setImage(Reset.Button.image(for: .focused), for: .focused)
    } else {
      // Fallback on earlier versions
    }
    button.setImage(Reset.Button.image(for: .highlighted), for: .highlighted)
    button.setImage(Reset.Button.image(for: UIControlState()), for: UIControlState())
    button.setImage(Reset.Button.image(for: .reserved), for: .reserved)
    button.setImage(Reset.Button.image(for: .selected), for: .selected)

    button.setBackgroundImage(Reset.Button.backgroundImage(for: .disabled),
                              for: .disabled)
    if #available(iOS 9.0, *) {
      button.setBackgroundImage(Reset.Button.backgroundImage(for: .focused),
                                for: .focused)
    } else {
      // Fallback on earlier versions
    }
    button.setBackgroundImage(Reset.Button.backgroundImage(for: .highlighted),
                              for: .highlighted)
    button.setBackgroundImage(Reset.Button.backgroundImage(for: UIControlState()),
                              for: UIControlState())
    button.setBackgroundImage(Reset.Button.backgroundImage(for: .reserved),
                              for: .reserved)
    button.setBackgroundImage(Reset.Button.backgroundImage(for: .selected),
                              for: .selected)

    button.setAttributedTitle(Reset.Button.attributedTitle(for: .disabled),
                              for: .disabled)
    if #available(iOS 9.0, *) {
      button.setAttributedTitle(Reset.Button.attributedTitle(for: .focused),
                                for: .focused)
    } else {
      // Fallback on earlier versions
    }
    button.setAttributedTitle(Reset.Button.attributedTitle(for: .highlighted),
                              for: .highlighted)
    button.setAttributedTitle(Reset.Button.attributedTitle(for: UIControlState()),
                              for: UIControlState())
    button.setAttributedTitle(Reset.Button.attributedTitle(for: .reserved),
                              for: .reserved)
    button.setAttributedTitle(Reset.Button.attributedTitle(for: .selected),
                              for: .selected)
    Reset.resetTargets(button)
  }

  fileprivate static let ImageView = UIImageView()
  fileprivate static func resetImageView(_ imageView: UIImageView) {
    Reset.resetView(imageView, proto: Reset.ImageView)
    imageView.backgroundColor = Reset.ImageView.backgroundColor
    imageView.image = Reset.ImageView.image
    imageView.isHighlighted = Reset.ImageView.isHighlighted
    imageView.highlightedImage = Reset.ImageView.highlightedImage
    imageView.animationImages = Reset.ImageView.animationImages
    imageView.highlightedAnimationImages = Reset.ImageView.highlightedAnimationImages
    imageView.animationDuration = Reset.ImageView.animationDuration
    imageView.animationRepeatCount = Reset.ImageView.animationRepeatCount
    imageView.tintColor = Reset.ImageView.tintColor
    Reset.resetTargets(imageView)
  }

  static func resetTargets(_ view: UIView?) {
    guard let view = view else { return }
    if let control = view as? UIControl {
      for target in control.allTargets {
        control.removeTarget(target, action: nil, for: .allEvents)
      }
    }
  }
}

extension UIView {

  func css_reset() {
    Reset.resetCssView(self)
  }

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

  /// content-size calculation for the scrollview should be applied after the layout.
  /// This is called after the scroll view is rendered.
  /// TableViews and CollectionViews are excluded from this post-render pass.
  func postRender() {
    if let scrollView = self as? UIScrollView {
      if let _ = self as? UITableView { return }
      if let _ = self as? UICollectionView { return }
      scrollView.postRender()
    }
  }
}

extension UIScrollView {

  func postRender() {
    var x: CGFloat = 0
    var y: CGFloat = 0
    for subview in self.subviews {
      x = subview.frame.maxX > x ? subview.frame.maxX : x
      y = subview.frame.maxY > y ? subview.frame.maxY : y
    }
    self.contentSize = CGSize(width: x, height: y)
    self.isScrollEnabled = true
  }
}

public extension CGSize {

  /// Undefined size.
  public static let undefined = CGSize(width: CGFloat(CSSNaN()), height: CGFloat(CSSNaN()))

  public static func sizeConstraintToHeight(_ height: CGFloat) -> CGSize {
    return CGSize(width: CGFloat(CSSNaN()), height: height)
  }

  public static func sizeConstraintToWidth(_ width: CGFloat) -> CGSize {
    return CGSize(width: width, height: CGFloat(CSSNaN()))
  }

  /// Returns true is this value is less than .19209290E-07F
  public var isZero: Bool {
    return self.width < CGFloat(FLT_EPSILON) && self.height < CGFloat(FLT_EPSILON)
  }
}
