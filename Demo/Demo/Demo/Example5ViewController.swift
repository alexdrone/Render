import Foundation
import UIKit
import Render

// from https://github.com/alexdrone/Render/issues/34

class ListState: StateType { }

class ListComponentView: ComponentView<ListState> {

  override func construct(state: ListState?, size: CGSize) -> NodeType {

    let list = TableNode() { (view, layout, size) in
      layout.width = size.width
      layout.height = size.height
      view.backgroundColor = Color.black
      view.separatorStyle = .none
    }

    list.children =  [

      // Any node definition will be wrapped inside a UITableViewCell.
      Node<UIView> { (view, layout, size) in
        layout.width = size.width
        layout.height = 300
        view.backgroundColor = Color.green
      },

      Node<UIView> { (view, layout, size) in
        layout.width = size.width
        layout.height = 100
        view.backgroundColor = Color.red
      },

      // A node definition.
      Node<UIView> { (view, layout, size) in
        layout.width = size.width
        layout.height = 300
        view.backgroundColor = Color.darkerGreen
      },

      // ComponentViews can also be added to the TableNode.
      HelloWorldComponentView().construct(state: HelloWorldState(name:"Foo"), size: size)
    ]
    return list
  }

}

class Example5ViewController: UIViewController {

  let component = ListComponentView()

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = Color.white
    self.view.addSubview(component)
    self.title = "EXAMPLE 5"
    component.render(in: self.view.frame.size)
  }


  override func viewDidLayoutSubviews() {
    component.render(in: self.view.bounds.size)
    component.center = self.view.center
  }
}

