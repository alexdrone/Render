import UIKit
import Render

class Example3ViewController: ViewController {

  private let scrollableComponent = ScrollableDemoComponentView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(scrollableComponent)
  }

}

