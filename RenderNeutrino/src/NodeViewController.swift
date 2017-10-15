import UIKit

open class UINodeViewController<N: UINodeProtocol>: UIViewController, UINodeDelegateProtocol {
  public var node: N!

  open override func viewDidLoad() {
    super.viewDidLoad()
    node = constructNode()
    render()
  }

  /// Your view controller subclass must instantiate and configure your node hierarchy here.
  open func constructNode() -> N {
    fatalError("Your subclass should instantiate and configure your node here.")
  }

  /// Runs the reconciliation algorithm and re-layout the node.
  open func render() {
    node.reconcile(in: view, size: view.bounds.size, options: [])
  }

  open override func viewDidLayoutSubviews() {
    node.layout(in: view.bounds.size, options: [])
    node.renderedView?.center = view.center
  }

  /// The view got rendered and added to the view hierarchy.
  open func nodeDidMount(_ node: UINodeProtocol, view: UIView) { }

  /// The view is about to be layed out.
  open func nodeWillLayout(_ node: UINodeProtocol, view: UIView) { }

  /// The view just got layed out.
  open func nodeDidLayout(_ node: UINodeProtocol, view: UIView) { }
}
