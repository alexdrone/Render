import SwiftUI
import CoreRender
import Render

struct ContentView: View {
    var body: some View {
      VStack {
        Text("Hello World")
        CoreRenderBridgeView { context in
          VStackNode {
            LabelNode(text: "Hello World")
            EmptyNode()
          }
        }
      }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
