import UIKit
import RenderNeutrino

class TextProps: UIPropsProtocol, Codable {
  var text = "Hello"
  required init() {
  }
}

class ViewController: UIViewController {

  let context = UIContext()
  var component: UI.Components.FooTable!
  let safeAreaView = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()

    let bridge = UIJsFragmentBuilder()
    bridge.loadDefinition(source:
    """
    ui.style.padding = function(props, size) {
      return { padding: 25, backgroundColor: color(ui.color.coral) }
    }

    ui.fragment.paddedLabel = function(props, size) {
      return Node(UIView, null, { padding: 25,
                                  backgroundColor: color(ui.color.coral),
                                  width: size.width }, [
        Node(UILabel, null, { text: props.text ,
                              font: font(ui.font.system, 12, ui.font.weight.regular) }, null)
      ])
    }
    """
    )
    let node = bridge.buildFragment(function: "paddedLabel", props: TextProps(), canvasSize: view.bounds.size)
    node.reconcile(in: view, size: view.bounds.size, options: [])

//    component = context.component(UI.Components.FooTable.self, key: "main")
//
//    safeAreaView.translatesAutoresizingMaskIntoConstraints = false
//    safeAreaView.backgroundColor = UIColor.blue
//    var constraints: [NSLayoutConstraint] = []
//    if #available(iOS 11.0, *) {
//      constraints = [
//        safeAreaView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//        safeAreaView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
//        safeAreaView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
//        safeAreaView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
//      ]
//    } else {
//      constraints = [
//        safeAreaView.topAnchor.constraint(equalTo: view.topAnchor),
//        safeAreaView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        safeAreaView.leftAnchor.constraint(equalTo: view.leftAnchor),
//        safeAreaView.rightAnchor.constraint(equalTo: view.rightAnchor),
//      ]
//    }
//    view.addSubview(safeAreaView)
//    NSLayoutConstraint.activate(constraints)
//    component.setCanvas(view: safeAreaView)
  }

}
