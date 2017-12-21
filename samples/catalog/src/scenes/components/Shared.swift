import UIKit
import RenderNeutrino

func makePolygon() -> UINodeProtocol {
  // By using the create closure instead of the configuration one, the view settings are
  // applied only once.
  // - Note: You need to specify a custom 'reuseIdentifier.
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
