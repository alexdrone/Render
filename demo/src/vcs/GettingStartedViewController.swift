import UIKit
import RenderNeutrino

class GettingStartedViewController: UITableComponentViewController {

  lazy var indexProps: [Index.CellProps] = {
    return [
      Index.CellProps(
        title: "Getting Started I",
        subtitle: "Simple stateless component.",
        onCellSelected: presentSimpleCounterExample1),
      Index.CellProps(
        title: "Getting Started II",
        subtitle: "A stateful counter.",
        onCellSelected: presentSimpleCounterExample2),
      Index.CellProps(
        title: "Getting Started III",
        subtitle: "A stateful counter with props externally injected.",
        onCellSelected: presentSimpleCounterExample3),
      Index.CellProps(
        title: "Getting Started IV",
        subtitle: "Introducing styles.",
        onCellSelected: presentSimpleCounterExample4),
      Index.CellProps(
        title: "Getting Started V",
        subtitle: "YAML Stylesheet and hot reload.",
        onCellSelected: presentSimpleCounterExample5),
      ]
  }()

  override func renderCellDescriptors() -> [UIComponentCellDescriptor] {
    return indexProps.enumerated().compactMap { (index: Int, props: Index.CellProps) in
      let cmp =  context.component(Index.Cell.self, key: "\(index)", props: props, parent: nil)
      return UIComponentCellDescriptor(component: cmp)
    }
  }

  /// Called after the controller's view is loaded into memory.
  override func viewDidLoad() {
    styleNavigationBarComponent(title: "Getting Started")
    super.viewDidLoad()
  }

  // MARK: UITableViewDataSource

  @objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    didSelectRowAt(props: indexProps, indexPath: indexPath)
  }

  @objc func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
    didHighlightRowAt(props: indexProps, indexPath: indexPath)
  }

  private func presentSimpleCounterExample1() {
    navigationController?.pushViewController(SimpleCounterViewController1(), animated: true)
  }

  private func presentSimpleCounterExample2() {
    navigationController?.pushViewController(SimpleCounterViewController2(), animated: true)
  }

  private func presentSimpleCounterExample3() {
    navigationController?.pushViewController(SimpleCounterViewController3(), animated: true)
  }

  private func presentSimpleCounterExample4() {
    navigationController?.pushViewController(SimpleCounterViewController4(), animated: true)
  }

  private func presentSimpleCounterExample5() {
    navigationController?.pushViewController(SimpleCounterViewController5(), animated: true)
  }

  private func presentTransitionDemo() {
    navigationController?.pushViewController(TransitionFromDemoViewController(), animated: true)
  }
}

