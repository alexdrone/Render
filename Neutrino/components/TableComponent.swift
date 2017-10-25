import UIKit

// MARK: - UITableViewComponentProps

public class UITableComponentProps: UIPropsProtocol {
  /// Represents a table view section.
  public struct Section {
    /// The list of components that are going to be shown in this section.
    public var components: [UIComponentProtocol]
    /// A node able to render this section header.
    /// - note: Optional.
    public var header: UIComponentProtocol?
    /// 'true' if all of the root nodes in this section have a unique key.
    public var hasDistinctKeys: Bool {
      let set: Set<String> = Set(components.flatMap { $0.key })
      return set.count == components.count
    }

    public init(components: [UIComponentProtocol], header: UIComponentProtocol? = nil) {
      self.components = components
      self.header = header
    }
  }
  /// The sections that will be presented by this table view instance.
  public var sections: [Section] = []
  /// The table view header component.
  public var header: UIComponentProtocol?
  /// 'true' if all of the root nodes, in all of the sections have a unique key.
  public var hasDistinctKeys: Bool {
    return sections.filter { $0.hasDistinctKeys }.count == sections.count
  }
  /// Returns all of the components across the different sections.
  public var allComponents: [UIComponentProtocol] {
    var components: [UIComponentProtocol] = []
    for section in sections {
      components.append(contentsOf: section.components)
    }
    return components
  }

  /// Additional *UITableView* configuration closure.
  /// - note: Use this to configure layout properties such as padding, margin and such.
  public var configuration: (UITableView, CGSize) -> Void = { view, canvasSize in
    view.yoga.width = canvasSize.width
    view.yoga.height = canvasSize.height
  }

  public required init() { }
}

// MARK: - UITableComponent

private let prototypeCell = UITableComponentCell(style: .default, reuseIdentifier: "")

public typealias UIDefaultTableComponent = UITableComponent<UINilState, UITableComponentProps>

/// Wraps a *UITableView* into a Render component.
public class UITableComponent<S: UIStateProtocol, P: UITableComponentProps>:
  UIComponent<S, P>, UIContextDelegate, UITableViewDataSource, UITableViewDelegate {

  /// The concrete backing view.
  private var tableView: UITableView? {
    return root.renderedView as? UITableView
  }

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
      table.delegate = self
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
      self.props.configuration(table, UIScreen.main.bounds.size)
      /// Implements padding as content insets.
      table.contentInset.bottom = table.yoga.paddingBottom.normal
      table.contentInset.top = table.yoga.paddingTop.normal
      table.contentInset.left = table.yoga.paddingLeft.normal
      table.contentInset.right = table.yoga.paddingRight.normal
    }
  }

  public func setNeedRenderInvoked(on context: UIContextProtocol, component: UIComponentProtocol) {
    guard context === self.context else {
      fatalError("This component is registered as a delegate for a different context.")
    }
    // If a children changed updates the table view layout.
    guard !componentIsChild(component) else {
      tableView?.beginUpdates()
      tableView?.endUpdates()
      return
    }
    // Registers the nodes as unamanged children.
    var nodes: [UINodeProtocol] = []
    for section in props.sections {
      nodes.append(contentsOf: section.components.map { $0.asNode() })
    }
    root.unmanagedChildren = nodes

    // TODO: Integrate IGListDiff algorithm.
    tableView?.reloadData()
  }

  // Returns 'true' if the component passed as argument is a child of this table.
  private func componentIsChild(_ component: UIComponentProtocol) -> Bool {
    for child in props.allComponents {
      if componentIsEqual(child, component) { return true }
    }
    return false
  }

  private func componentIsEqual(_ c1: UIComponentProtocol, _ c2: UIComponentProtocol) -> Bool {
    // Compare pointer identity.
    if c1 === c2 { return true }
    // Compare unique keys.
    if let c1Key = c1.key, let c2Key = c2.key, c1Key == c2Key { return true }
    return false
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
    return props.sections[section].components.count
  }

  /// Asks the data source for a cell to insert in a particular location of the table view.
  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let component = props.sections[indexPath.section].components[indexPath.row]
    component.delegate = self
    let node = component.asNode()
    let reuseIdentifier = node.reuseIdentifier
    // Dequeue the right cell.
    let cell: UITableComponentCell =
      tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? UITableComponentCell
      ?? UITableComponentCell(style: .default, reuseIdentifier: reuseIdentifier)
    // Mounts the new node.
    cell.mount(component: component, width: tableView.bounds.size.width)

    return cell
  }

  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let node = props.sections[indexPath.section].components[indexPath.row].asNode()
    node.reconcile(in: prototypeCell.contentView,
                   size: CGSize(width: tableView.bounds.size.width, height: CGFloat.max),
                   options: [.preventDelegateCallbacks])
    return prototypeCell.contentView.subviews.first?.bounds.size.height ?? 0
  }

  /// Retrieves the component from the context for the key passed as argument.
  /// If no component is registered yet, a new one will be allocated and returned.
  /// - parameter type: The desired *UIComponent* subclass.
  /// - parameter key: The unique key ('nil' for a transient component).
  /// - parameter props: Configurations and callbacks passed down to the component.
  public func cell<S, P, C: UIComponent<S, P>>(_ type: C.Type,
                                               key: String? = nil,
                                               props: P = P()) -> C {
    guard let context = context else {
      fatalError("Attempting to create a component without a valid context.")
    }
    if let key = key {
      return context.component(type, key: key, props: props, parent: nil)
    } else {
      return context.transientComponent(type, props: props, parent: nil)
    }
  }
}

// MARK: - UITableViewComponentCell

public class UITableComponentCell: UITableViewCell {
  /// The node currently associated to this view.
  public var component: UIComponentProtocol?

  public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func mount(component: UIComponentProtocol, width: CGFloat) {
    self.component = component
    component.setCanvas(view: contentView, options: [])
    component.canvasSize = {
      return CGSize(width: width, height: CGFloat.max)
    }
    component.root.reconcile(in: contentView,
                             size: CGSize(width: width, height: CGFloat.max),
                             options: [.preventDelegateCallbacks])

    guard let componentView = contentView.subviews.first else {
      return
    }
    contentView.frame.size = componentView.bounds.size
    contentView.backgroundColor = componentView.backgroundColor
    backgroundColor = componentView.backgroundColor
  }

  /// Asks the view to calculate and return the size that best fits the specified size.
  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    guard let component = component else {
      return .zero
    }
    mount(component: component, width: size.width)
    return contentView.frame.size
  }
}
