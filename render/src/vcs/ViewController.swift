import UIKit

open class UIComponentViewController<C: UIComponentProtocol>: UIBaseViewController,
                                                              UINodeDelegateProtocol {
  /// The root component for this viewController.
  public var component: C!

  /// Subclasses should override this method and constructs the root component by using the
  /// view controller context. e.g.
  ///
  ///     return self.context.component(MyComponent.self, key: self.rootKey)
  ///
  open func buildRootComponent() -> C {
    fatalError("Subclasses should override this method to build the root component.")
  }

  /// Called after the controller's view is loaded into memory.
  /// - note: Set the ViewController *rootKey* before calling the super implementation.
  open override func viewDidLoad() {
    super.viewDidLoad()
    component = buildRootComponent()
    component.setCanvas(view: canvasView, options: UIComponentCanvasOption.defaults())
  }

  open override func render(options: [UIComponentRenderOption] = []) {
    super.render()
    component.setNeedsRender(options: options)
  }

  /// Notifies the container that the size of its view is about to change.
  /// - note: if *shouldRenderAlongsideSizeTransitionAnimation* is 'true' than the component is
  /// going to be rendered alongside the orientation change transition.
  override open func viewWillTransition(
    to size: CGSize,
    with coordinator: UIViewControllerTransitionCoordinator
  ) -> Void {
    super.viewWillTransition(to: size, with: coordinator)

    let renderAlongside = shouldRenderAlongsideSizeTransitionAnimation
    let component: UIComponentProtocol = self.component
    coordinator.animate(alongsideTransition: { [weak self] _ in
      self?.renderNavigationBar()
      if renderAlongside {
        component.setNeedsRender(options: [])
      }
    }) { [weak self] _ in
      component.setNeedsRender(options: [])
      self?.renderNavigationBar()
    }
  }

  /// The backing view of *node* just got rendered and added to the view hierarchy.
  /// - parameter view: The view that just got installed in the view hierarchy.
  /// - note: Override this if you need specific post-render adjustments, or if you want to
  /// coordinate the setup of views that don't belong to the component view hierarchy.
  open func nodeDidMount(_ node: UINodeProtocol, view: UIView) { }

  /// The backing view of *node* is about to be layed out.
  /// - parameter view: The view that is about to be configured and layed out.
  /// - note: Override this if you need specific post-render adjustments, or if you want to
  /// coordinate the setup of views that don't belong to the component view hierarchy.
  open func nodeWillLayout(_ node: UINodeProtocol, view: UIView) {  }

  /// The backing view of *node* just got layed out.
  /// - parameter view: The view that has just been configured and layed out.
  /// - note: Override this if you need specific post-render adjustments, or if you want to
  /// coordinate the setup of views that don't belong to the component view hierarchy.
  open func nodeDidLayout(_ node: UINodeProtocol, view: UIView) {
    adjustScrollViewContentSizeAfterComponentDidRender()
  }

  public func adjustScrollViewContentSizeAfterComponentDidRender() {
    guard let scrollView = self.canvasView as? UIScrollView else { return }
    scrollView.adjustContentSizeAfterComponentDidRender()
  }
}

open class UIScrollableComponentViewController<C:UIComponentProtocol>: UIComponentViewController<C>{
  /// Returns a *UIScrollView* as its canvas view.
  open override func buildCanvasView() -> UIView {
    let view = UIScrollView()
    view.delegate = self
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }

  /// Tells the delegate when the user scrolls the content view within the receiver.
  /// - note: This is currently used to coordinate the expansion of the component-based navigation
  /// bar.
  @objc public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    navigationBarDidScroll(scrollView)
  }
}
