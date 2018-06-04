import UIKit
import RenderNeutrino

class TransitionDemoProps: UIProps {
  var onTapAction: () -> (Void) = { }
}

// MARK: - From

class TransitionFromComponent: UIStatelessComponent<TransitionDemoProps> {

  override func render(context: UIContextProtocol) -> UINodeProtocol {
    let container = UINode<UIView> { spec in
      spec.view.yoga.width = spec.canvasSize.width
      spec.view.yoga.height = 80
      spec.view.yoga.flexDirection = .row
      spec.view.onTap { [weak self] _ in
        self?.props.onTapAction()
      }
    }
    let image = UINode<UIView> { spec in
      spec.view.yoga.width = 80
      spec.view.yoga.height = 80
      spec.view.backgroundColor = .red
      spec.view.cornerRadius = 40
      spec.view.makeTransitionable(key: "image", mode: .copy)
    }
    let title = UINode<UILabel> { spec in
      spec.view.textColor = .white
      spec.view.font = UIFont.boldSystemFont(ofSize: 20)
      spec.view.text = "From"
      spec.view.yoga.margin = 8
      spec.view.makeTransitionable(key: "title", mode: .copy)
    }
    return container.children([image, title])
  }
}

// MARK: - To

class TransitionToComponent: UIStatelessComponent<TransitionDemoProps> {

  override func render(context: UIContextProtocol) -> UINodeProtocol {
    let container = UINode<UIView> { spec in
      spec.view.yoga.width = 160
      spec.view.onTap { [weak self] _ in
        self?.props.onTapAction()
      }
    }
    let image = UINode<UIView>() { spec in
      spec.view.yoga.width = 160
      spec.view.yoga.height = 160
      spec.view.backgroundColor = .red
      spec.view.makeTransitionable(key: "image", mode: .copy)
    }
    let title = UINode<UILabel> { spec in
      spec.view.textColor = .white
      spec.view.font = UIFont.boldSystemFont(ofSize: 32)
      spec.view.text = "To"
      spec.view.yoga.margin = 8
      spec.view.makeTransitionable(key: "title", mode: .copy)
    }
    return container.children([image, title])
  }
}
