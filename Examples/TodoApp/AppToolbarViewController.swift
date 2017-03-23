import UIKit
import Material
import Dispatcher_iOS

class AppToolbarController: ToolbarController {

  let dispatcher: Dispatcher

  init(rootViewController: UIViewController, dispatcher: Dispatcher = Dispatcher.default) {
    self.dispatcher = dispatcher
    super.init(rootViewController: rootViewController)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func prepare() {
    super.prepare()
    let cancelButton = IconButton(image: Icon.cm.close, tintColor: .white)
    cancelButton.pulseColor = .white
    cancelButton.addTarget(self, action: #selector(didTapCancelAllButton), for: .touchUpInside)

    let button = IconButton(image: Icon.cm.add, tintColor: .white)
    button.pulseColor = .white
    button.addTarget(self, action: #selector(didTapAddButton), for: .touchUpInside)

    statusBarStyle = .lightContent
    statusBar.backgroundColor = Color.pink.darken2
    toolbar.backgroundColor = Color.pink.darken1
    toolbar.leftViews = [cancelButton]
    toolbar.rightViews = [button]

    toolbar.title = "Todos"
    toolbar.titleLabel.textColor = UIColor.white
  }

  dynamic private func didTapAddButton() {
    self.dispatcher.dispatch(action: Action.add)
  }

  dynamic private func didTapCancelAllButton() {
    self.dispatcher.dispatch(action: Action.clear)
  }
}
