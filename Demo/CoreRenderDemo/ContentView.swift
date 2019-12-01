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
          .alignItems(.center)
          .background(UIColor.systemGroupedBackground)
          .matchHostingViewWidth(withMargin: 0)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
