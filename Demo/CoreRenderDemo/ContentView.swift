import SwiftUI
import CoreRender
import Render

struct ContentView: View {
  var body: some View {
    VStack {
      Text("Hello From SwiftUI")
      CoreRenderBridgeView { context in
        VStackNode {
          LabelNode(text: "Hello")
            .font(UIFont.boldSystemFont(ofSize: 12))
            .textAlignment(.center)
            .padding(8)
          LabelNode(text: "From")
            .textAlignment(.center)
            .font(UIFont.boldSystemFont(ofSize: 12))
            .padding(8)
          LabelNode(text: "CoreRender")
            .textAlignment(.center)
            .font(UIFont.boldSystemFont(ofSize: 14))
            .padding(8)
        }
          .alignItems(.flexEnd)
          .background(UIColor.systemGroupedBackground)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
      .previewLayout(.fixed(width: 320, height: 240))

  }
}
