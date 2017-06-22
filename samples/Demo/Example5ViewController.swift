import UIKit
import Render

class Example5ViewController: ViewController {

  private let component = PercentComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(component)
  }

  override func viewDidLayoutSubviews() {
    component.update(in: self.view.bounds.size)
    component.center = self.view.center
  }
}

