import UIKit
import RenderMicro

class ViewController: UINodeViewController<PaddedLabel.Node> {

  override func constructNode() -> PaddedLabel.Node {
    return PaddedLabel.Node(key: "main-label")
  }

}
