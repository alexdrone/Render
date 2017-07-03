import Foundation
import UIKit

public protocol ListNodeType: NodeType {

  /// The component that is owning this table.
  weak var parentComponent: AnyComponentView? { get }

  /// Set this property to 'true' if you want to disable the built-in cell reuse mechanism.
  /// This could be beneficial when the number of items is limited and you wish to improve the
  /// overall scroll performance.
  var disableCellReuse: Bool { get set }

  /// Computes and applies the diff to the collection by adding and removing rows rather then
  /// calling reloadData.
  var shouldUseDiff: Bool { get set }

  // Internal use only.
  var internalChildren: [NodeType] { get set }

  var internalNode: NodeType { get }
}

public extension ListNodeType {

  /// The UITableView associated to this node.
  public var renderedView: UIView? {
    return internalNode.renderedView
  }

  /// The associated component (if applicable).
  public weak var associatedComponent: AnyComponentView? {
    get { return internalNode.associatedComponent }
    set { internalNode.associatedComponent = newValue }
  }

  /// The reference size for the cells.
  public func referenceSize() -> CGSize {
    let width = self.renderedView?.bounds.size.width ?? 0
    let height = CGFloat.max
    return CGSize(width: width, height: height)
  }

  public func node(for indexPath: IndexPath) -> (String, NodeType) {
    let node = internalChildren[indexPath.row]
    let identifier = disableCellReuse ? node.key.stringValue : node.key.reuseIdentifier
    return (identifier, node)
  }

  public func mount(node: NodeType,
                    cell: ComponentCellType,
                    parent: AnyComponentView?,
                    in listView: UIView,
                    at indexPath: IndexPath) {
    if let component = parent?.childrenComponent[node.key] {
      cell.mountComponentIfNecessary(isStateful: true, component)
    } else {
      cell.mountComponentIfNecessary(isStateful: true, StatelessComponent { _ in node })
    }
    cell.componentView?.associatedCell = cell
    cell.componentView?.referenceSize = referenceSize
    cell.listView = listView
    cell.currentIndexPath = indexPath
    cell.update(options: [.preventViewHierarchyDiff])
    node.associatedComponent?.didUpdate()
  }

  /// The children are bypassed and used to implement the UITableView's datasource.
  public var children: [NodeType] {
    set {
      var index = 0
      let children = newValue.filter { child in !(child is NilNode) }
      for child in children where !(child is NilNode) {
        child.index = index
        index += 1
      }
      internalChildren = children;
    }
    get {
      return []
    }
  }

  /// Adds the nodes passed as argument as subnodes.
  @discardableResult public func add(children: [NodeType]) -> NodeType {
    self.children += children
    return self
  }

  /// Adds the node passed as argument as subnode.
  @discardableResult public func add(child: NodeType) -> NodeType {
    self.children = children + [child]
    return self
  }

  /// Internal use only.
  /// The configuration block for this node.
  public func configure(in bounds: CGSize) {
    internalNode.configure(in: bounds)
  }

  /// 'willMount' is not yet supported for ListNode.
  public func willLayout() { }

  /// 'didMount' is not yet supported for ListNode.
  public func didLayout() { }

  /// Asks the node to build the backing view for this node.
  public func build(with reusable: UIView?) {
    internalNode.build(with: reusable)
  }
}

/// Wraps a UITableView in a node definition.
/// TableNode.children will be wrapped into UITableViewCell.
/// Consider using TableNode over Node<ScrollView> where you have a big number of items to be
/// displayed.
public class TableNode: NSObject, ListNodeType, UITableViewDataSource, UITableViewDelegate {

  /// TableNode redirects all of the layout calls to a Node<TableView>.
  /// Essentially this class is just a proxy in oder to hide the 'children' collection to the
  /// node hierarchy and to implement the UITableView's datasource.
  private let node: Node<UITableView>
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

  /// The component that is owning this table.
  public weak private(set) var parentComponent: AnyComponentView?

  public var internalChildren: [NodeType] = []
  public var internalOldChildren: [NodeType] = []

  public init(reuseIdentifier: String = String(describing: UITableView.self),
              key: String,
              parent: AnyComponentView,
              children: [NodeType] = [],
              configure: @escaping Node<UITableView>.ConfigureBlock = { _ in }) {

    self.node = Node(reuseIdentifier: reuseIdentifier,
                     key: key,
                     resetBeforeReuse: false,
                     children: [],
                     create: { return UITableView() },
                     configure: configure)
    self.internalChildren = children
    self.key = Key(reuseIdentifier: reuseIdentifier, key: key)
    self.parentComponent = parent
  }

  public func layout(in bounds: CGSize) {
    configure(in: bounds)
  }

  /// Re-applies the configuration closures to the UITableView and reload the data source.
  public func configure(in bounds: CGSize) {
    node.layout(in: bounds)
    guard let table = renderedView as? UITableView else {
      return
    }
    if #available(iOS 11, *) {
      table.estimatedRowHeight = -1;
    } else {
      table.estimatedRowHeight = 64;
    }
    table.estimatedRowHeight = 64;
    table.rowHeight = UITableViewAutomaticDimension
    table.dataSource = self
    //table.delegate = self
    table.separatorStyle = .none

    if shouldUseDiff, let old = parentComponent?.childrenKeyMap[key] {
      let set = Set(internalChildren.map { $0.key })
      guard set.count == internalChildren.count else {
        print("Unable to apply diff when table nodes don't all have a distinct key.")
        table.reloadData()
        return
      }
      let new = internalChildren.map { $0.key }
      let threshold = maximumNuberOfDiffUpdates
      let diff = old.diff(new)
      if diff.insertions.count < threshold  && diff.deletions.count < threshold  {
        table.beginUpdates()
        table.deleteRows(at: diff.deletions.map { IndexPath(row: Int($0.idx), section: 0) },
                         with: .fade)
        table.insertRows(at: diff.insertions.map { IndexPath(row: Int($0.idx), section: 0) },
                         with: .fade)
        table.endUpdates()
      } else {
        table.reloadData()
      }
    } else {
      table.reloadData()
    }
    parentComponent?.childrenKeyMap[key] = internalChildren.map { $0.key }

  }

  //MARK: - UITableViewDataSource

  /// Tells the data source to return the number of rows in a given section of a table view.
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return internalChildren.count
  }

  /// Asks the data source for a cell to insert in a particular location of the table view.
  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let (identifier, node) = self.node(for: indexPath)
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? ComponentTableViewCell
               ?? ComponentTableViewCell()
    mount(node: node, cell: cell, parent: parentComponent, in: tableView, at: indexPath)
    return cell
  }
}


