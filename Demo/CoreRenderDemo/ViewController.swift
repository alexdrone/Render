import UIKit
import CoreRender
import CoreRenderObjC

class ViewCoordinator: UIViewController {
  var hostingView: HostingView!
  let context = Context()

  override func loadView() {
    hostingView = HostingView(context: context, with: [.useSafeAreaInsets]) { context in
      Component<DemoWidgetCoordinator>(context: context) { context, coordinator in
        makeDemoWidget(context: context, coordinator: coordinator)
      }.builder()
    }
    self.view = hostingView
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    hostingView.setNeedsLayout()
  }
}
