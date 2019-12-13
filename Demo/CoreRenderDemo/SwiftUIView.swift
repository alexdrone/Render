import SwiftUI
import CoreRender
import Render

struct SwiftUIView: View {
  var body: some View {
    VStack {
      CoreRenderBridgeView { _ in
        LabelNode(text: "Hi from Render")
          .font(UIFont.systemFont(ofSize: 12))
          .padding(12)
      }
    }
  }
}

struct SwiftUIView_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUIView()
  }
}
