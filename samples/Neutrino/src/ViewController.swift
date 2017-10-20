import UIKit
import RenderNeutrino
import UI

class ViewController: UIViewController {

  let context = UIContext()
  var component: PaddedLabel.Component!
  let safeAreaView = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    component = context.component(PaddedLabel.Component.self, key: "main")

    safeAreaView.translatesAutoresizingMaskIntoConstraints = false
    safeAreaView.backgroundColor = UIColor.blue
    let constraints = [
      safeAreaView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      safeAreaView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      safeAreaView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      safeAreaView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
    ]
    view.addSubview(safeAreaView)
    NSLayoutConstraint.activate(constraints)
    component.setCanvas(view: safeAreaView)
  }

}
