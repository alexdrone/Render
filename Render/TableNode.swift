import Foundation
import UIKit

struct AnyNode: Equatable {
  let node: NodeType
  static func ==(lhs: AnyNode, rhs: AnyNode) -> Bool {
    return lhs.node.key == rhs.node.key
  }
}

/// Wraps a UITableView in a node definition.
/// TableNode.children will be wrapped into UITableViewCell.
/// Consider using TableNode over Node<ScrollView> where you have a big number of items to be
/// displayed.
public class TableNode: NSObject, NodeType, UITableViewDataSource, UITableViewDelegate {

  /// TableNode redirects all of the layout calls to a Node<TableView>.
  /// Essentially this class is just a proxy in oder to hide the 'children' collection to the
  /// node hierarchy and to implement the UITableView's datasource.
  private let node: Node<UITableView>

  /// The UITableView associated to this node.
  public var renderedView: UIView? {
    return node.renderedView
  }

  /// The unique identifier for this node is its hierarchy.
  public var key: Key

  /// Set this property to 'true' if you want to disable the built-in cell reuse mechanism.
  /// This could be beneficial when the number of items is limited and you wish to improve the
  /// overall scroll performance.
  public var disableCellReuse: Bool = false

  /// Computes and applies the diff to the collection by adding and removing rows rather then
  /// calling reloadData.
  public var shouldUseDiff: Bool = false
  public var maximumNuberOfDiffUpdates: Int = 50

  /// This component is the n-th children.
  public var index: Int = 0 {
    didSet { node.index = index }
  }

  /// The associated component (if applicable).
  public weak var associatedComponent: AnyComponentView? {
    get { return node.associatedComponent }
    set { node.associatedComponent = newValue }
  }

  /// The component that is owning this table.
  private weak var parentComponent: AnyComponentView?

  private var internalChildren: [NodeType] = []
  private var internalOldChildren: [NodeType] = []

  /// The children are bypassed and used to implement the UITableView's datasource.
  public var children: [NodeType] {
    set {
      internalOldChildren = internalChildren
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

  public init(reuseIdentifier: String = String(describing: UITableView.self),
              key: String = "",
              parent: AnyComponentView,
              children: [NodeType] = [],
              create: @escaping Node<UITableView>.CreateBlock = { return UITableView() },
              configure: @escaping Node<UITableView>.ConfigureBlock = { _ in }) {

    self.node = Node(reuseIdentifier: reuseIdentifier,
                     key: key,
                     resetBeforeReuse: false,
                     children: [],
                     create: create,
                     configure: configure)
    self.internalChildren = children
    self.key = Key(reuseIdentifier: reuseIdentifier, key: key)
    self.parentComponent = parent
  }

  /// Re-applies the configuration closures to the UITableView and reload the data source.
  public func layout(in bounds: CGSize) {
    node.layout(in: bounds)
    guard let table = renderedView as? UITableView else {
      return
    }
    table.estimatedRowHeight = -1;
    table.rowHeight = UITableViewAutomaticDimension
    table.dataSource = self

    if shouldUseDiff {
      let set = Set( internalChildren.map { $0.key })
      guard set.count == internalChildren.count else {
        print("Unable to apply diff when table nodes don't all have a distinct key.")
        table.reloadData()
        return
      }
      let old = internalOldChildren.map { AnyNode(node: $0) }
      let new = internalChildren.map { AnyNode(node: $0) }
      let threshold = maximumNuberOfDiffUpdates
      let diff = old.diff(new)
      if diff.insertions.count < threshold  && diff.deletions.count < threshold  {
        table.beginUpdates()
        table.deleteRows(at: diff.deletions.map { IndexPath(row: Int($0.idx), section: 0) },
                         with: .automatic)
        table.insertRows(at: diff.insertions.map { IndexPath(row: Int($0.idx), section: 0) },
                         with: .automatic)
        table.endUpdates()
      } else {
        table.reloadData()
      }
    } else {
      table.reloadData()
    }
  }

  /// Internal use only.
  /// The configuration block for this node.
  public func configure(in bounds: CGSize) {
    node.configure(in: bounds)
  }

  /// 'willMount' is not yet supported for TableNode.
  public func willLayout() { }

  /// 'didMount' is not yet supported for TableNode.
  public func didLayout() { }

  /// Asks the node to build the backing view for this node.
  public func build(with reusable: UIView?) {
    node.build(with: reusable)
  }

  //MARK: - UITableViewDataSource

  /// Tells the data source to return the number of rows in a given section of a table view.
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return internalChildren.count
  }

  /// Asks the data source for a cell to insert in a particular location of the table view.
  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let node = internalChildren[indexPath.row]
    var identifier = node.key.reuseIdentifier
    if disableCellReuse {
      identifier = node.key.stringValue
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? ComponentTableViewCell
               ?? ComponentTableViewCell()

    if let component = parentComponent?.childrenComponent[node.key] {
      cell.mountComponentIfNecessary(forceMount: true, component)
    } else {
      let component = NilStateComponentView()
      cell.mountComponentIfNecessary(component)
      component.renderBlock = { _, _ in return node }
    }
    cell.update(options: [.preventViewHierarchyDiff])
    node.associatedComponent?.didUpdate()
    return cell
  }
}

