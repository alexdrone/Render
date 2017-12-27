import UIKit
import RenderNeutrino

func makePolygon() -> UINode<UIPolygonView> {
  // By using the create closure instead of the configuration one, the view settings are
  // applied only once.
  // - note: You need to specify a custom 'reuseIdentifier.
  return UINode<UIPolygonView>(reuseIdentifier: "polygon", create: {
    let view = UIPolygonView()
    view.foregroundColor = Palette.white.color
    view.yoga.width = 44
    view.yoga.height = 44
    view.yoga.marginRight = Margin.medium.cgFloat
    view.depthPreset = .depth1
    return view
  })
}

public func makeButton(reuseIdentifier: String = "button",
                       text: String,
                       onTouchUpInside: @escaping () -> Void = { },
                       configure: UINode<UIButton>.ConfigurationClosure?=nil) -> UINode<UIButton> {
  func makeButton() -> UIButton {
    let view = UIButton()
    view.backgroundColorImage = Palette.white.color
    view.textColor = Palette.primary.color
    view.depthPreset = .depth1
    view.cornerRadiusPreset = .cornerRadius1
    view.yoga.padding = Margin.small.cgFloat
    view.titleLabel?.font = Typography.smallBold.font
    return view
  }
  return UINode<UIButton>(reuseIdentifier: reuseIdentifier, create: makeButton) { config in
    config.view.setTitle(text, for: .normal)
    config.view.onTap { _ in onTouchUpInside() }
  }
}

public func makeLabel(text: String,
                      configure: UINode<UILabel>.ConfigurationClosure?=nil) -> UINode<UILabel> {
  return UINode<UILabel> { config in
    config.set(\UILabel.text, text)
    config.set(\UILabel.numberOfLines, 0)
    config.set(\UILabel.textColor, Palette.white.color)
    configure?(config)
  }
}

public func makeTapRecognizer(reuseIdentifier: String = "tapRecognizer",
                              onTouchUpInside: @escaping () -> Void = { },
                              configure: UINode<UIView>.ConfigurationClosure?=nil)->UINode<UIView> {
  return UINode<UIView>(reuseIdentifier: reuseIdentifier) { config in
    config.view.onTap { _ in onTouchUpInside() }
    configure?(config)
  }
}
