import Foundation
import UIKit

/// Wraps a UICollectionView in a node definition.
/// CollectionNode.children will be wrapped into UICollectionView.
/// Consider using TableNode over Node<ScrollView> where you have a big number of items to be
/// displayed.
public class CollectionNode: NSObject, ListNodeType, UICollectionViewDataSource,
                             UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

  /// CollectionNode redirects all of the layout calls to a Node<UICollectionView>.
  /// Essentially this class is just a proxy in oder to hide the 'children' collection to the
  /// node hierarchy and to implement the UICollectionView's datasource.
  private let node: Node<UICollectionView>
  public var internalNode: NodeType {
    return node
  }

  /// The unique identifier for this node is its hierarchy.
  public var key: Key

  public var disableCellReuse: Bool = false
  public var shouldUseDiff: Bool = false
  public var maximumNuberOfDiffUpdates: Int = 50

  /// This component is the n-th children.
  public var index: Int = 0 {
    didSet { node.index = index }
  }
  public let debugType: String = String(describing: UICollectionView.self)

  /// The component that is owning this table.
  public weak private(set) var rootComponent: AnyComponentView?

  public var internalChildren: [NodeType] = []

  public init(reuseIdentifier: String = String(describing: UICollectionView.self),
              key: String,
              in rootComponent: AnyComponentView,
              layout: UICollectionViewLayout = CollectionNode.defaultCollectionViewLayout(),
              props: @escaping Node<UICollectionView>.PropsBlock = { _ in }) {
    self.node = Node(reuseIdentifier: reuseIdentifier,
                     key: key,
                     resetBeforeReuse: false,
                     children: [],
                     create: { UICollectionView(frame: CGRect.zero, collectionViewLayout: layout) },
                     props: props)
    self.internalChildren = []
    self.key = Key(reuseIdentifier: reuseIdentifier, key: key)
    self.rootComponent = rootComponent
  }

  @available(*, unavailable)
  public init(reuseIdentifier: String = String(describing: UICollectionView.self),
              key: String = "",
              resetBeforeReuse: Bool = false,
              children: [NodeType] = [],
              create: @escaping Node<UICollectionView>.CreateBlock = { UICollectionView() },
              props: @escaping Node<UICollectionView>.PropsBlock = { _ in }) {
    self.node = Node(reuseIdentifier: reuseIdentifier,
                     key: key,
                     resetBeforeReuse: resetBeforeReuse,
                     children: children,
                     create: create,
                     props: props)
    self.key = Key(reuseIdentifier: reuseIdentifier, key: key)
    self.rootComponent = nil
  }

  public static func defaultCollectionViewLayout() -> UICollectionViewLayout {
    return ListCollectionViewLayout(stickyHeaders: false,
                                    topContentInset: 0,
                                    stretchToEdge: false)
  }

  public func layout(in bounds: CGSize) {
    configure(in: bounds)
  }

  /// Re-applies the configuration closures to the UITableView and reload the data source.
  public func configure(in bounds: CGSize) {
    node.layout(in: bounds)
    guard let collectionView = renderedView as? UICollectionView else {
      return
    }
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.contentInset.bottom = collectionView.yoga.paddingBottom.normal
    collectionView.contentInset.top = collectionView.yoga.paddingTop.normal
    collectionView.contentInset.left = collectionView.yoga.paddingLeft.normal
    collectionView.contentInset.right = collectionView.yoga.paddingRight.normal
    collectionView.reloadData()
  }

  //MARK: - UICollectionViewDatasource

  /// Tells the data source to return the number of rows in a given section of a collection view.
  public func collectionView(_ collectionView: UICollectionView,
                             numberOfItemsInSection section: Int) -> Int {
    return internalChildren.count
  }

  public func collectionView(_ collectionView: UICollectionView,
                             layout collectionViewLayout: UICollectionViewLayout,
                             sizeForItemAt indexPath: IndexPath) -> CGSize {
    let (_, node) = self.node(for: indexPath)
    let component = rootComponent?.childrenComponent[node.key]
                    ?? StatelessPrototypeCellComponentView { _ in  node }
    component.referenceSize = {_ in 
      return CGSize(width: collectionView.bounds.size.width, height: CGFloat.max)
    }
    return component.intrinsicContentSize
  }

  /// Asks the data source for a cell to insert in a particular location of the collection view.
  public func collectionView(_ collectionView: UICollectionView,
                             cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let (identifier, node) = self.node(for: indexPath)
    collectionView.register(InternalComponentCollectionViewCell.self,
                            forCellWithReuseIdentifier: identifier)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier,
                                                  for: indexPath)
               as! InternalComponentCollectionViewCell
    mount(node: node, cell: cell, rootComponent: rootComponent, for: (collectionView, indexPath))
    return cell
  }
}
