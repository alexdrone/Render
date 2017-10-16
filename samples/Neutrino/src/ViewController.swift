import UIKit
import RenderNeutrino
import UI

class ViewController: UINodeViewController {

  override func constructNode() -> UINodeProtocol {
    return PaddedLabel.Node(key: "main-label")
  }

}
