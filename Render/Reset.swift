import Foundation
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
    guard view.yoga.isEnabled else {
      return
    }
    view.yoga.direction = proto.yoga.direction
    view.yoga.flexDirection = proto.yoga.flexDirection
    view.yoga.justifyContent = proto.yoga.justifyContent
    view.yoga.flexDirection = proto.yoga.flexDirection
    view.yoga.alignContent = proto.yoga.alignContent
    view.yoga.alignSelf = proto.yoga.alignSelf
    view.yoga.alignItems = proto.yoga.alignItems
    view.yoga.position = proto.yoga.position
    view.yoga.flexWrap = proto.yoga.flexWrap
    view.yoga.flexGrow = proto.yoga.flexGrow
    view.yoga.flexShrink = proto.yoga.flexShrink
    view.yoga.flexBasis = proto.yoga.flexBasis
    view.yoga.width = proto.yoga.width
    view.yoga.height = proto.yoga.height
    view.yoga.minHeight = proto.yoga.minHeight
    view.yoga.minWidth = proto.yoga.minWidth
    view.yoga.maxHeight = proto.yoga.maxHeight
    view.yoga.maxWidth = proto.yoga.maxWidth
    view.yoga.padding = proto.yoga.padding
    view.yoga.paddingTop = proto.yoga.paddingTop
    view.yoga.paddingLeft = proto.yoga.paddingLeft
    view.yoga.paddingRight = proto.yoga.paddingRight
    view.yoga.paddingBottom = proto.yoga.paddingBottom
    view.yoga.margin = proto.yoga.margin
    view.yoga.marginTop = proto.yoga.marginTop
    view.yoga.marginLeft = proto.yoga.marginLeft
    view.yoga.marginRight = proto.yoga.marginRight
    view.yoga.marginBottom = proto.yoga.marginBottom
    view.yoga.aspectRatio = proto.yoga.aspectRatio
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

protocol PostRendering {

  /** content-size calculation for the scrollview should be applied after the layout.
   *  This is called after the scroll view is rendered.
   *  TableViews and CollectionViews are excluded from this post-render pass.
   */
  func postRender()
}

extension UIScrollView: PostRendering {

  func postRender() {
    if let _ = self as? UITableView { return }
    if let _ = self as? UICollectionView { return }
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
