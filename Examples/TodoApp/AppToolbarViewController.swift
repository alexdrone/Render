import UIKit
import Material

class AppToolbarController: ToolbarController {

  let store: Store

  init(rootViewController: UIViewController, store: Store) {
    self.store = store
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
    self.store.dispatch(action: .add)
  }

  dynamic private func didTapCancelAllButton() {
    self.store.dispatch(action: .clear)
  }
}
