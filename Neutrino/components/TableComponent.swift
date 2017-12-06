import UIKit

// MARK: - UITableViewComponentProps

open class UITableCellProps: UIPropsProtocol {
  public required init() { }
  /// Cell title.
  public var title = String()
  /// Cell subtitle.
  public var subtitle = String()
  /// Automatically set to 'true' whenever the cell is being highlighted.
  public var isHighlighted: Bool = false
  /// The closure that is going to be executed whenever the cell is selected.
  public var onCellSelected: (() -> Void)? = nil

  public init(title: String, subtitle: String = "", onCellSelected: @escaping () -> Void) {
    self.title = title
    self.subtitle = subtitle
    self.onCellSelected = onCellSelected
  }
}

public class UITableComponentProps: UIPropsProtocol {
  /// Represents a table view section.
  public struct Section {
    /// The list of components that are going to be shown in this section.
    public var cells: [UICellDescriptor]
    /// A node able to render this section header.
    /// - note: Optional.
    public var header: UISectionHeader?
    /// 'true' if all of the root nodes in this section have a unique key.
    public var hasDistinctKeys: Bool {
      let set: Set<String> = Set(cells.flatMap { $0.component.key })
      return set.count == cells.count
    }
    /// *Optional optimisation* if the rows in this section have a pre-defined height,
    /// this will improve the overall component render time.
    public var defaultRowHeight: CGFloat? = nil
    public var estimatedRowHeight: CGFloat = 64

    public init(cells: [UICellDescriptor], header: UISectionHeader? = nil) {
      self.cells = cells
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
      components.append(contentsOf: section.cells.flatMap { $0.component })
    }
    return components
  }

  public typealias UITableNodeConfigurationClosure = UINode<UITableView>.ConfigurationClosure

  /// *UITableView* configuration closure.
  /// - note: Use this to configure layout properties such as padding, margin and such.
  public var configuration: UITableNodeConfigurationClosure = { _ in }

  public required init() { }

  public convenience init(sections: [Section], configure: UITableNodeConfigurationClosure? = nil) {
    self.init()
    self.sections = sections
    configuration = configure ?? configuration
  }

  public convenience init(cells: [UICellDescriptor],
                          header: UISectionHeader? = nil,
                          configure: UITableNodeConfigurationClosure? = nil) {
    self.init()
    sections.append(Section(cells: cells, header: header))
    configuration = configure ?? configuration
  }
}

// MARK: - UITableComponent

public typealias UIDefaultTableComponent = UITableComponent<UINilState, UITableComponentProps>

/// Wraps a *UITableView* into a Render component.
public class UITableComponent<S: UIStateProtocol, P: UITableComponentProps>:
  UIComponent<S, P>, UIContextDelegate, UITableViewDataSource, UITableViewDelegate {

  /// The concrete backing view.
  private var tableView: UITableView? {
    return root.renderedView as? UITableView
  }
  private var tableNode: UINodeProtocol!
  private var cellContext: UIContext!
  private var prototypes: [String: UIView] = [:]

  public required init(context: UIContextProtocol, key: String?) {
    guard let key = key else {
      fatalError("UITableComponent's *key* property is mandatory.")
    }
    super.init(context: context, key: key)
    tableNode = buildTable(context: context)
    cellContext = UICellContext()
    cellContext.registerDelegate(self)
    cellContext._parentContext = context
    context.registerDelegate(self)
  }

  public override func render(context: UIContextProtocol) -> UINodeProtocol {
    return tableNode
  }

  /// Construct the *UITableView* root node.
  private func buildTable(context: UIContextProtocol) -> UINodeProtocol {
    // Init closure.
    func makeTable() -> UITableView {
      let table = UITableView()
      table.dataSource = self
      table.delegate = self
      table.separatorStyle = .none
      table.estimatedRowHeight = 64
      table.rowHeight = UITableViewAutomaticDimension
      table.allowsMultipleSelection = false
      return table
    }
    return UINode<UITableView>(reuseIdentifier: "UITableComponent",
                               key: key,
                               create: makeTable) { [weak self] config in
      guard let `self` = self else {
        return
      }
      let table = config.view
      // Default configuration.
      config.set(\UITableView.yoga.width, context.screen.canvasSize.width)
      config.set(\UITableView.yoga.height, context.screen.canvasSize.height)
      // Custom configuration.
      self.props.configuration(config)
      /// Implements padding as content insets.
      table.contentInset.bottom = table.yoga.paddingBottom.normal
      table.contentInset.top = table.yoga.paddingTop.normal
      table.contentInset.left = table.yoga.paddingLeft.normal
      table.contentInset.right = table.yoga.paddingRight.normal
    }
  }

  /// Called when ⌘ + R is pressed to reload the component.
  override func forceComponentReload() {
    self.context?.jsBridge.initJSContext()
    self.setNeedsRender()
  }

  public func setNeedRenderInvoked(on context: UIContextProtocol, component: UIComponentProtocol) {
    cellContext._canvasView = tableView
    // Change comes from one of the parent components.
    if context === self.context {
      // TODO: Integrate IGListDiff algorithm.
      tableView?.reloadData()

    // Change come from one of the children component.
    } else if context === self.cellContext {
      tableView?.beginUpdates()
      tableView?.endUpdates()
    }
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
    return props.sections[section].cells.count
  }

  /// Asks the data source for a cell to insert in a particular location of the table view.
  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cellInfo = props.sections[indexPath.section].cells[indexPath.row]
    let component = cellInfo.component
    let _ = component.asNode()
    let reuseIdentifier = String(describing: type(of: component))
    let cell: UITableComponentCell =
      tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? UITableComponentCell
      ?? UITableComponentCell(style: .default, reuseIdentifier: reuseIdentifier)
    component.delegate = self
    disableImplicitAnimations {
      cell.selectionStyle = cellInfo.selectionStyle
      cell.mount(component: component, width: tableView.bounds.size.width)
    }
    return cell
  }

  /// Asks the delegate for the height to use for a row in a specified location.
  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let section = props.sections[indexPath.section]
    if let height = section.defaultRowHeight { return height }
    let component = props.sections[indexPath.section].cells[indexPath.row].component
    let node = component.asNode()
    let reuseIdentifier = String(describing: type(of: component))

    if prototypes[reuseIdentifier] == nil {
      prototypes[reuseIdentifier] = UIView()
    }
    let prototypeView = prototypes[reuseIdentifier]!
    disableImplicitAnimations {
      node.reconcile(in: prototypeView,
                     size: CGSize(width: tableView.bounds.size.width, height: CGFloat.max),
                     options: [.preventDelegateCallbacks])
    }
    return heightForComponentView(prototypeView.subviews.first)
  }

  private func heightForComponentView(_ view: UIView?) -> CGFloat {
    guard let cv = view else { return 0 }
    return cv.bounds.size.height + cv.yoga.marginTop.normal + cv.yoga.marginBottom.normal
  }

  private func disableImplicitAnimations(closure: () -> Void) {
    UIView.performWithoutAnimation {
      CATransaction.begin()
      CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
      closure()
      CATransaction.commit()
    }
  }

  /// Asks the delegate for a view object to display in the header of the specified section of
  /// the table view.
  public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let header = props.sections[section].header else {
      return UIView()
    }
    let view = UIView()
    let width = tableView.bounds.size.width
    header.component.asNode().reconcile(in: view,
                                        size: CGSize(width: width, height: CGFloat.max),
                                        options: [.preventDelegateCallbacks])
    view.sizeToFit()
    return view
  }

  /// Tells the delegate that the specified row is now selected.
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let component = props.sections[indexPath.section].cells[indexPath.row].component
    guard let cellProps = component.anyProps as? UITableCellProps else { return }
    cellProps.onCellSelected?()

    for idx in tableView.indexPathsForVisibleRows ?? [] where indexPath != idx {
      highlightCell(false, at: idx)
    }
    highlightCell(true, at: indexPath)
  }

  public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    highlightCell(false, at: indexPath)
  }

  private func highlightCell(_ isHighlighted: Bool, at indexPath: IndexPath) {
    let component = props.sections[indexPath.section].cells[indexPath.row].component
    guard let cellProps = component.anyProps as? UITableCellProps else { return }
    cellProps.isHighlighted = isHighlighted
    component.setNeedsRender(options: [])
  }

//  public func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
//    highlightCell(true, at: indexPath)
//  }

  /// Asks the delegate for the height to use for the header of a particular section.
  public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
    guard let header = props.sections[section].header else {
      return 0
    }
    let view = UIView()
    let width = tableView.bounds.size.width
    header.component.asNode().reconcile(in: view,
                                        size: CGSize(width: width, height: CGFloat.max),
                                        options: [.preventDelegateCallbacks])

    return heightForComponentView(view.subviews.first)
  }

  /// Retrieves the component from the context for the key passed as argument.
  /// If no component is registered yet, a new one will be allocated and returned.
  /// - parameter type: The desired *UIComponent* subclass.
  /// - parameter key: The unique key ('nil' for a transient component).
  /// - parameter props: Configurations and callbacks passed down to the component.
  public func cell<S, P, C: UIComponent<S, P>>(_ type: C.Type,
                                               key: String? = nil,
                                               props: P = P()) -> UICellDescriptor {
    var component: UIComponentProtocol!
    if let key = key {
      component = cellContext.component(type, key: key, props: props, parent: nil)
    } else {
      component = cellContext.transientComponent(type, props: props, parent: nil)
    }
    return UICellDescriptor(component: component)
  }

  /// Retieves a component that is suitable as a table header.
  public func header<S, P, C: UIComponent<S, P>>(_ type: C.Type,
                                                 key: String? = nil,
                                                 props: P = P()) -> UISectionHeader {
    return cell(type, key: key, props: props)
  }

  public override func dispose() {
    super.dispose()
    cellContext.dispose()
  }
}

// MARK: - UICell

public final class UICellDescriptor {
  /// The constructed component.
  public let component: UIComponentProtocol
  /// The style of selected cells.
  public var selectionStyle: UITableViewCellSelectionStyle
  // Internal constructor.
  init(component: UIComponentProtocol,
       selectionStyle: UITableViewCellSelectionStyle = .none) {
    self.component = component
    self.selectionStyle = selectionStyle
  }
}

public typealias UISectionHeader = UICellDescriptor

// MARK: - UICellContext

/// Components that are embedded in cells have a different context.
public final class UICellContext: UIContext {
  /// Layout animator is not available for cells.
  public override var layoutAnimator: UIViewPropertyAnimator? {
    get { return nil }
    set { }
  }

  public override var canvasSize: CGSize {
    guard let context = _parentContext as? UIContext else {
      return .zero
    }
    return context.canvasSize
  }

  public override func flushObsoleteStates(validKeys: Set<String>) {
    /// The lifetime of the cells is diffirent from traditional components due to recycling
    /// and managed from *UITableComponent*.
  }
}

extension UIComponent {
  /// 'true' if this component is being used in a tableview or a collection view.
  var isEmbeddedInCell: Bool {
    return self.context is UICellContext
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

    // We purposely wont re-generate the node (by calling *asNode()*) because this has already
    // been called in the 'heightForRowAt' delegate method.
    // We just install the node in the right view hierarchy.
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
