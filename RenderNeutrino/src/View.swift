import UIKit

public protocol UINodeViewProtocol: class, UINodeDelegateProtocol {
  /// The root node of this view.
  var _node: UINodeProtocol! { get set }
  /// The node props.
  var _props: UINodePropsProtocol? { get set }
  /// Your view subclass must instantiate and configure your node hierarchy here.
 func constructNode() -> UINodeProtocol
  /// Reconcile and re-layout the view hierarchy.
  func render()
}

@IBDesignable open class UINodeView: UIView, UINodeViewProtocol {
  public var _node: UINodeProtocol!
  public var _props: UINodePropsProtocol?

  override public init(frame: CGRect) {
    super.init(frame: frame)
    _node = constructNode()
  }
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    _node = constructNode()
  }

  open func constructNode() -> UINodeProtocol {
    fatalError("Your subclass should instantiate and configure your node here.")
  }

  open func render() {
    _node = constructNode()
    _node.reconcile(in: self, size: bounds.size, options: [])
    _node.renderedView?.center = center
  }

  open override func layoutSubviews() {
    _node.reconcile(in: self, size: bounds.size, options: [])
  }

  open override func sizeToFit() {
    super.sizeToFit()
    render()
    frame.size = _node.renderedView?.frame.size ?? CGSize.zero
  }

  open func nodeDidMount(_ node: UINodeProtocol, view: UIView) { }

  open func nodeWillLayout(_ node: UINodeProtocol, view: UIView) { }

  open func nodeDidLayout(_ node: UINodeProtocol, view: UIView) { }
}

@IBDesignable open class UIStaticViewHierarchyNodeView: UINodeView {
  override public init(frame: CGRect) {
    super.init(frame: frame)
    _node.reconcile(in: self, size: bounds.size, options: [])
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    _node.reconcile(in: self, size: bounds.size, options: [])
  }

  open override func render() {
    // Render doesn't re-construct the node in this case.
    _node.layout(in: bounds.size, options: [])
    _node.renderedView?.center = center
  }
}

open class UINodeViewController: UIViewController, UINodeDelegateProtocol {
  public var node: UINodeProtocol!

  open override func viewDidLoad() {
    super.viewDidLoad()
    node = constructNode()
    render()
  }

  /// Your view controller subclass must instantiate and configure your node hierarchy here.
  open func constructNode() -> UINodeProtocol {
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

  open func nodeDidMount(_ node: UINodeProtocol, view: UIView) { }

  open func nodeWillLayout(_ node: UINodeProtocol, view: UIView) { }

  open func nodeDidLayout(_ node: UINodeProtocol, view: UIView) { }
}
