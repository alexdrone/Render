import Foundation
import UIKit

// MARK: - State protocol

public protocol StateType { }
public struct NilState: StateType { }

public enum RenderOptions {
  /** The 'construct' method is called just once.
   *  This means that render will simply re-apply the existing configuration for the nodes
   *  and compute the new layout accordingly.
   *  This is a very useful optimisation for components with a static view hierarchy. 
   */
  case preventViewHierarchyDiff
}

// MARK: - ComponentView protocol

public protocol AnyComponentView: class { }

public protocol ComponentViewType: AnyComponentView {

  associatedtype StateType

  var state: StateType? { get set }

  /** This will run 'construct' that generates a new virtual-tree for this component.
   *  The tree is then diffed against the current one and the changes are applied to current
   *  view hierarchy.
   *  The layout for the resulting view hierarchy is then re-computed.
   */
  func render(in bounds: CGSize, options: [RenderOptions])

  /** Asks the view to calculate and return the size that best fits the specified size. */
  func sizeThatFits(_ size: CGSize) -> CGSize

  /** The natural size for the receiving view, considering only properties of the view itself. */
  var intrinsicContentSize : CGSize { get }
}

// MARK: - Implementation

/** Components let you split the UI into independent, reusable pieces, and think about each 
 *  piece in isolation.
 *  A component represents a function that maps a state S to its representation.
 *  The infrastructure below takes care of applying the minimal set of diffs whenever it is 
 *  necessary.
 */
open class ComponentView<S: StateType>: UIView, ComponentViewType {

  public typealias StateType = S

  /** The state of the component. Call 'render' on this component after the new state is set. */
  public var state: S? = nil

  /** The component's default options. */
  public var defaultOptions: [RenderOptions] = []

  /** The (current) root node. */
  private var root: NodeType = NilNode()

  /** The (current) view associated to the root node. */
  private var rootView: UIView!
  private lazy var contentView: UIView = {
    return UIView()
  }()

  /** Wether the 'root' node has been constructed yet. */
  private var initialized: Bool = false

  public init() {
    super.init(frame: CGRect.zero)
    self.rootView = self.root.renderedView
    self.addSubview(contentView)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  open func construct(state: S?, size: CGSize = CGSize.undefined) -> NodeType {
    print("Subclasses should override this method.")
    return NilNode()
  }

  open func willRender() { }

  public func render(in bounds: CGSize = CGSize.max, options: [RenderOptions] = []) {
    assert(Thread.isMainThread)
    self.willRender()
    let startTime = CFAbsoluteTimeGetCurrent()

    // Applies the configuration closures recursively.
    internalRender(in: bounds, options: options)

    debugRenderTime("\(type(of: self)).render", startTime: startTime)
    self.didRender()
  }

  private func internalRender(in bounds: CGSize = CGSize.max, options: [RenderOptions]) {
    let opts = self.defaultOptions + options

    // Reconstructs the tree and computes the diff.
    if !initialized || !opts.contains(.preventViewHierarchyDiff) {
      self.root = self.construct(state: self.state, size: bounds)
      self.reconcile(new: self.root, size: bounds, view: self.rootView, parent: self.contentView)
      self.rootView = self.root.renderedView!
    }
    self.initialized = true

    // Applies the configuration closures and recursively computes the layout.
    self.root.render(in: bounds)
    self.rootView.yoga.applyLayout(preservingOrigin: false)
    let yoga = self.rootView.yoga


    // Applies the frame to the host view.
    self.rootView.frame.normalize()
    self.contentView.frame.size = rootView.bounds.size

    func normalize(_ value: CGFloat) -> CGFloat { return value.isNormal ? value : 0 }
    self.contentView.frame.size.height += normalize(yoga.marginTop) + normalize(yoga.marginBottom)
    self.contentView.frame.size.width +=  normalize(yoga.marginLeft) + normalize(yoga.marginRight)
    self.frame = self.contentView.bounds
  }

  open func didRender() { }

  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    assert(Thread.isMainThread)
    self.render(in: size)
    return self.rootView.yoga.intrinsicSize
  }

  open override var intrinsicContentSize : CGSize {
    assert(Thread.isMainThread)
    return sizeThatFits(CGSize.max)
  }

  /** Reconciliation algorithm for the view hierarchy. */
  private func reconcile(new: NodeType, size: CGSize, view: UIView?, parent: UIView) {
    assert(Thread.isMainThread)
    if let view = view, view.hasNode && view.tag == new.identifier.hashValue {
      new.build(with: view)
    } else {
      view?.removeFromSuperview()
      new.build(with: nil)
      parent.insertSubview(new.renderedView!, at: new.index)
    }
    var oldSubviews = view?.subviews.filter { $0.hasNode }
    for subnode in new.children {
      let candidateView = oldSubviews?.filter { $0.tag == subnode.identifier.hashValue }.first
      oldSubviews = oldSubviews?.filter { $0 !== candidateView }
      reconcile(new: subnode, size: size, view: candidateView, parent: new.renderedView!)
    }
    oldSubviews?.forEach { $0.removeFromSuperview() }
  }
}

// MARK: - Utilities

func debugRenderTime(_ label: String, startTime: CFAbsoluteTime, threshold: CFAbsoluteTime = 16) {
  let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime)*1000

  // - Note: 60fps means you need to render a frame every ~16ms to not drop any frames.
  // This is even more important when used inside a cell.
  if timeElapsed > threshold  {
    print(String(format: "\(label) (%2f) ms.", arguments: [timeElapsed]))
  }
}
