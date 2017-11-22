im

port UIKit



import RenderNeutrino

class IndexViewController: UIComponentViewController<UI.Components.IndexTable> {

  override func buildRootComponent() -> UI.Components.IndexTable {
    let props = UI.Props.IndexTable()ù





    props.titles = [
      UI.Props.IndexCell(
        title: "Card Example",
        subtitle: "A complex stateful component.",
        onCellSelected: presentAppStoreEntryComponentExample),
      UI.Props.IndexCell(
        title: "Card List Example",
        subtitle: "A list of stateful components.",
        onCellSelected: presentAppStoreListComponentExample),
      UI.Props.IndexCell(
        title: "A Component with JS fragments.",
        subtitle: "And hot reload capabilities.",
        onCellSelected: presentJsCounterExample),
    ]
    return context.component(UI.Components.IndexTable.self, key: rootKey, props: props)
  }

  private func presentAppStoreEntryComponentExample() {
    func makeComponent(context: UIContextProtocol) -> UI.Components.AppStoreEntry {
      return context.component(UI.Components.AppStoreEntry.self,
                               key: "appstore-example",
                               props: UI.Props.AppStoreEntry.singleCardExample(),
                               parent: nil)
    }
    let vc = VC<UI.Components.AppStoreEntry>(title: "APP STORE",
                                             buildRootComponent: makeComponent)
    navigationController?.pushViewController(vc, animated: true)
  }

  private func presentAppStoreListComponentExample() {
    func makeComponent(context: UIContextProtocol) -> UI.Components.AppStoreList {
      return context.component(UI.Components.AppStoreList.self,
                               key: "appstore-example-list",
                               props: UINilProps.nil,
                               parent: nil)
    }
    let vc = VC<UI.Components.AppStoreList>(title: "APP STORE LIST",
                                            buildRootComponent: makeComponent)
    navigationController?.pushViewController(vc, animated: true)
  }

  private func presentJsCounterExample() {
    func makeComponent(context: UIContextProtocol) -> UI.Components.JsCounter {
      return context.component(UI.Components.JsCounter.self,
                               key: "jscounter",
                               props: UINilProps.nil,
                               parent: nil)
    }
    let vc = VC<UI.Components.JsCounter>(title: "JAVASCRIPT FRAGMENTS",
                                            buildRootComponent: makeComponent)
    navigationController?.pushViewController(vc, animated: true)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.title = "NEUTRINO CATALOG"
    styleNavigationBar()
  }
}

class VC<T: UIComponentProtocol>: UIComponentViewController<T> {
  private let buildRootComponentClosure: (UIContextProtocol) -> T

  init(title: String, buildRootComponent: @escaping (UIContextProtocol) -> T) {
    self.buildRootComponentClosure = buildRootComponent
    super.init(nibName: nil, bundle: nil)
    self.title = title
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func buildRootComponent() -> T {
    return buildRootComponentClosure(context)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = context.stylesheet.palette(Palette.primary)
    navigationItem.title = title
    styleNavigationBar()
  }
}

