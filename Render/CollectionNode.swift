import Foundation
import UIKit

public class CollectionNode: NodeType {

  public typealias CreateBlock = (Void) -> UICollectionView
  public typealias ConfigureBlock = (UICollectionView, YGLayout, CGSize) -> (Void)

  /** The underlying view rendered from the node. */
  public private(set) var renderedView: UIView? {
    get { return self.view }
    set { self.view = newValue as? UICollectionView }
  }
  public private(set) var view: UICollectionView?

  public var identifier: String

  /** The configuration block for this node. */
  private let configure: ConfigureBlock
  private let create: CreateBlock

  /** The current children of this node. */
  public var children: [NodeType] = [] {
    didSet {
      var index = 0
      for child in self.children where !(child is NilNode) {
        child.index = index
        index += 1
      }
    }
  }

  public func add(children: [NodeType]) -> NodeType {
    let nodes = children.filter { node in !(node is NilNode) }
    self.children = nodes
    return self
  }

  public func add(child: NodeType) {
    guard !(child is NilNode) else {
      return
    }
    children = children + [child]
  }

  public var index: Int = 0

  public init(identifier: String = String(describing: CollectionNode.self),
              children: [NodeType] = [],
              create: @escaping CreateBlock = CollectionNode.defaultCreate,
              configure: @escaping  ConfigureBlock = { _ in }) {
    self.identifier = identifier
    self.create = create
    self.configure = configure
    self.children = children
  }

  public func render(in bounds: CGSize) {
    assert(Thread.isMainThread)
    internalConfigure(in: bounds)
    guard let view = self.view else {
      fatalError()
    }
    view.bounds.size = bounds
    view.yoga.applyLayout(preservingOrigin: false)
    view.bounds.size = view.yoga.intrinsicSize
    view.yoga.applyLayout(preservingOrigin: false)
  }

  public func internalConfigure(in bounds: CGSize) {
    self.build()
    for child in self.children {
      child.internalConfigure(in: bounds)
    }
    self.configure(self.view!, self.view!.yoga, bounds)
    if let yoga = self.view?.yoga, yoga.isEnabled && yoga.isLeaf {
      if !(self.view is ComponentViewType) {
        yoga.markDirty()
      }
    }

  }

  // Not supported for the 'ListNode' yet.
  public func willRender() { }
  public func didRender() { }

  public func build(with reusable: UIView? = nil) {
    guard self.view == nil else { return }
    if let reusable = reusable as? UICollectionView {
      self.view = reusable
    } else {
      self.view = self.create()
      self.view?.yoga.isEnabled = true
      self.view?.tag = identifier.hashValue
      self.view?.hasNode = true
    }
  }

  static let defaultCreate: CreateBlock = {
      let collectionView = UICollectionView()
      collectionView.collectionViewLayout = UICollectionViewFlowLayout()
      return collectionView
  }
}
