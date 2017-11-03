import UIKit
import RenderNeutrino

class TextProps: UIPropsProtocol, Codable {
  var text = "Hello"
  required init() {
  }
}

class ViewController: UIViewController {

  let context = UIContext()
  var component: UI.Components.JsCounter!
  let safeAreaView = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    component = context.component(UI.Components.JsCounter.self, key: "main")

    safeAreaView.translatesAutoresizingMaskIntoConstraints = false
    safeAreaView.backgroundColor = Color.black
    var constraints: [NSLayoutConstraint] = []
    if #available(iOS 11.0, *) {
      constraints = [
        safeAreaView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        safeAreaView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        safeAreaView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
        safeAreaView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
      ]
    } else {
      constraints = [
        safeAreaView.topAnchor.constraint(equalTo: view.topAnchor),
        safeAreaView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        safeAreaView.leftAnchor.constraint(equalTo: view.leftAnchor),
        safeAreaView.rightAnchor.constraint(equalTo: view.rightAnchor),
      ]
    }
    view.addSubview(safeAreaView)
    NSLayoutConstraint.activate(constraints)
    component.setCanvas(view: safeAreaView)
  }
}
