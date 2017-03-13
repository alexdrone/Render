import Foundation
import UIKit
import Render

// from https://github.com/alexdrone/Render/issues/34

struct AppState: StateType {
  var isOn = false
}

class NilComponentView: ComponentView<AppState> {
  override func construct(state: AppState?, size: CGSize) -> NodeType {
    let children = state!.isOn ? []: [Node<UIView>()]
    return Node<UIView>().add(children: children)
  }
}

class Example5ViewController: UIViewController {

  let component = NilComponentView()

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = Color.white
    self.view.addSubview(component)
    self.title = "EXAMPLE 1"
    generateRandomStates()
  }

  func generateRandomStates() {
    component.state = AppState()
    component.render(in: self.view.frame.size)
    component.state?.isOn = true
    component.render(in: self.view.frame.size)
  }

  override func viewDidLayoutSubviews() {
    component.render(in: self.view.bounds.size)
    component.center = self.view.center
  }
}

