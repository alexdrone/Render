import Foundation
import UIKit

/** Wraps a UITableView in a node definition.
 *  TableNode.children will be wrapped into UITableViewCell.
 *  Consider using TableNode over Node<ScrollView> where you have a big number of items to be 
 *  displayed.
 */
public class TableNode: NSObject, NodeType, UITableViewDataSource, UITableViewDelegate {

  /** TableNode redirects all of the layout calls to a Node<TableView>.
   *  Essentially this class is just a proxy in oder to hide the 'children' collection to the
   *  node hierarchy and to implement the UITableView's datasource.
   */
  private let node: Node<UITableView>

  /** The UITableView associated to this node. */
  public var renderedView: UIView? {
    return node.renderedView
  }

  /** The unique identifier for this node is its hierarchy. */
  public let identifier: String

  /** Set this property to 'true' if you want to disable the built-in cell reuse mechanism. 
   *  This could be beneficial when the number of items is limited and you wish to improve the
   *  overall scroll performance.
   */
  public var disableCellReuse: Bool = false

  /** This component is the n-th children. */
  public var index: Int = 0 {
    didSet {
      node.index = index
    }
  }

  private var _children: [NodeType] = []

  /** The children are bypassed and used to implement the UITableView's datasource. */
  public var children: [NodeType] {
    set {
      var index = 0
      let children = newValue.filter { child in !(child is NilNode) }
      for child in children where !(child is NilNode) {
        child.index = index
        index += 1
      }
      _children = children;
    }
    get {
      return []
    }
  }

  /** Adds the nodes passed as argument as subnodes. */
  @discardableResult public func add(children: [NodeType]) -> NodeType {
    self.children += children
    return self
  }

  /** Adds the node passed as argument as subnode. */
  @discardableResult public func add(child: NodeType) -> NodeType {
    self.children = children + [child]
    return self
  }

  public init(identifier: String = "CollectionNode",
              children: [NodeType] = [],
              create: @escaping Node<UITableView>.CreateBlock = { return UITableView() },
              configure: @escaping Node<UITableView>.ConfigureBlock = { _ in }) {

    self.node = Node(identifier: identifier,
                     resetBeforeReuse: false,
                     children: [],
                     create: create,
                     configure: configure)
    self._children = children
    self.identifier = identifier
  }

  /** Re-applies the configuration closures to the UITableView and reload the data source. */
  public func render(in bounds: CGSize) {
    node.render(in: bounds)
    if let table = self.renderedView as? UITableView {
      table.estimatedRowHeight = 64;
      table.rowHeight = UITableViewAutomaticDimension
      table.dataSource = self
      table.reloadData()
    }
  }

  public func internalConfigure(in bounds: CGSize) {
    node.internalConfigure(in: bounds)
  }

  /** 'willRender' is not yet supported for TableNode. */
  public func willRender() { }

  /** 'didRender' is not yet supported for TableNode. */
  public func didRender() { }

  public func build(with reusable: UIView?) {
    node.build(with: reusable)
  }

  //MARK: - UITableViewDataSource

  /** Tells the data source to return the number of rows in a given section of a table view. */
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self._children.count
  }

  /**  Asks the data source for a cell to insert in a particular location of the table view. */
  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let node = self._children[indexPath.row]
    var identifier = node.identifier

    if self.disableCellReuse {
      identifier = "\(identifier)_\(indexPath.row)"
    }

    let cell: ComponentTableViewCell<NilStateComponentView> =
        tableView.dequeueReusableCell(withIdentifier: identifier)
            as? ComponentTableViewCell<NilStateComponentView> ??
        ComponentTableViewCell<NilStateComponentView>()

    cell.mountComponentIfNecessary(NilStateComponentView())
    cell.componentView?.constructBlock = { _, _ in return node }

    node.render(in: tableView.bounds.size)
    cell.render(in: tableView.bounds.size, options: [])

    return cell
  }
}


