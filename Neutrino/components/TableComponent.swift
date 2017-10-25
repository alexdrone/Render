import UIKit

// MARK: - UITableViewComponentProps

public class UITableComponentProps: UIPropsProtocol {
  /// Represents a table view section.
  public struct Section {
    /// The list of components that are going to be shown in this section.
    public var nodes: [UINodeProtocol]
    /// A node able to render this section header.
    /// - note: Optional.
    public var header: UINodeProtocol?
    /// 'true' if all of the root nodes in this section have a unique key.
    public var hasDistinctKeys: Bool {
      let set: Set<String> = Set(nodes.flatMap { $0.key })
      return set.count == nodes.count
    }

    public init(nodes: [UINodeProtocol], header: UINodeProtocol? = nil) {
      self.nodes = nodes
      self.header = header
    }
  }
  /// The sections that will be presented by this table view instance.
  public var sections: [Section] = []
  /// The table view header component.
  public var header: UINodeProtocol?
  /// 'true' if all of the root nodes, in all of the sections have a unique key.
  public var hasDistinctKeys: Bool {
    return sections.filter { $0.hasDistinctKeys }.count == sections.count
  }
  /// Additional *UITableView* configuration closure.
  /// - note: Use this to configure layout properties such as padding, margin and such.
  public var layout: (YGLayout, CGSize) -> Void = { layout, canvasSize in
    layout.width = canvasSize.width
    layout.height = canvasSize.height
  }

  public required init() { }
}

// MARK: - UITableComponent

public typealias UIDefaultTableComponent = UITableComponent<UINilState, UITableComponentProps>

/// Wraps a *UITableView* into a Render component.
public class UITableComponent<S: UIStateProtocol, P: UITableComponentProps>:
  UIComponent<S, P>, UIContextDelegate, UITableViewDataSource {

  /// The concrete backing view.
  private weak var tableView: UITableView?

  public required init(context: UIContextProtocol, key: String?) {
    super.init(context: context, key: key)
    context.registerDelegate(self)
  }

  /// Construct the *UITableView* root node.
  public override func render(context: UIContextProtocol) -> UINodeProtocol {
    guard let key = key else {
      fatalError("UITableComponent's *key* property is mandatory.")
    }
    // Init closure.
    func makeTable() -> UITableView {
      let table = UITableView()
      table.dataSource = self
      table.rowHeight = 275
      if #available(iOS 11, *) {
        table.estimatedRowHeight = -1;
      } else {
        table.estimatedRowHeight = 64;
      }
      table.separatorStyle = .none
      return table
    }
    return UINode<UITableView>(reuseIdentifier: "UITableComponent",
                               key: key,
                               create: makeTable) { [weak self] config in
      guard let `self` = self else {
        return
      }
      let table = config.view
      self.props.layout(table.yoga, context.canvasView?.bounds.size ?? .zero)
      /// Implements padding as content insets.
      table.contentInset.bottom = table.yoga.paddingBottom.normal
      table.contentInset.top = table.yoga.paddingTop.normal
      table.contentInset.left = table.yoga.paddingLeft.normal
      table.contentInset.right = table.yoga.paddingRight.normal
      config.node.bindView(target: self, keyPath: \UITableComponent.tableView)
    }
  }

  public func setNeedRenderInvoked(on context: UIContextProtocol) {
    guard context === self.context else {
      fatalError("This component is registered as a delegate for a different context.")
    }

    // Registers the nodes as unamanged children.
    var nodes: [UINodeProtocol] = []
    for section in props.sections {
      nodes.append(contentsOf: section.nodes)
    }
    root.unmanagedChildren = nodes

    // TODO: Integrate IGListDiff algorithm.
    tableView?.reloadData()
  }

  /// Asks the data source to return the number of sections in the table view.
  public func numberOfSections(in tableView: UITableView) -> Int {
    return props.sections.count
  }

  /// Tells the data source to return the number of rows in a given section of a table view.
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard section < props.sections.count else {
      fatalError("Attempts to access to a section out of bounds.")
    }
    return props.sections[section].nodes.count
  }

  /// Asks the data source for a cell to insert in a particular location of the table view.
  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let node = props.sections[indexPath.section].nodes[indexPath.row]
    let reuseIdentifier = node.reuseIdentifier
    // Dequeue the right cell.
    let cell: UITableComponentCell =
      tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? UITableComponentCell
      ?? UITableComponentCell(style: .default, reuseIdentifier: reuseIdentifier)
    // Mounts the new node.
    cell.mountNode(node: node, width: tableView.bounds.size.width)

    return cell
  }
}

// MARK: - UITableViewComponentCell

public class UITableComponentCell: UITableViewCell {
  /// The node currently associated to this view.
  public var node: UINodeProtocol = UINilNode.nil

  public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func mountNode(node: UINodeProtocol, width: CGFloat) {
    self.node = node
    let size = CGSize(width: width, height: CGFloat.max)
    node.reconcile(in: contentView, size: size, options: [])
    contentView.frame = contentView.subviews.first?.bounds ?? CGRect.zero
    contentView.subviews.first?.center = contentView.center
  }

  /// Asks the view to calculate and return the size that best fits the specified size.
  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    mountNode(node: self.node, width: size.width)
    return contentView.bounds.size
  }
}
