import UIKit
import CoreRender

class ViewController: UIViewController {
  private var node: ConcreteNode<UIView>?
  private var count = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    render()
  }

  func render() {
    count += 1
    node = Node(type: UIView.self) { spec in
      set(spec, keyPath: \UIView.yoga.width, value: spec.size.width)
    }
    let wrapper = Node(type: UIView.self) { spec in
      set(spec, keyPath: \UIView.backgroundColor, value: .lightGray)
      set(spec, keyPath: \UIView.cornerRadius, value: 5)
      set(spec, keyPath: \UIView.yoga.margin, value: 20)
      set(spec, keyPath: \UIView.yoga.padding, value: 20)
    }
    node?.append(children: [wrapper])

    let label = Node(type: UILabel.self) { spec in
      set(spec, keyPath: \UILabel.text, value: "Hello")
    }
    if count % 2 == 0 {
      wrapper.append(children: [label])
    }

    guard let view = view else { return }
    node?.reconcile(in: view, constrainedTo: view.bounds.size, with: [])
  }

  override func viewDidLayoutSubviews() {
    render()
  }



}

