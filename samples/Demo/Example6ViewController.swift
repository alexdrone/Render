import UIKit
import Render

class Example6ViewController: UIViewController {

  let component = PercentComponentView()

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = Color.black
    self.view.addSubview(component)
    self.title = "EXAMPLE 6"
  }

  override func viewDidLayoutSubviews() {
    component.render(in: self.view.bounds.size)
    component.center = self.view.center
  }
}

