import UIKit
import XCPlayground
import Render

/*:
 ![logo](logo_small.png)
 # Styling components

 **Render** offers a conventient way to apply and share styles among components.

 `ComponentStyle` is a simple struct with a closure that describe the styling for a component node.
 `ComponentStyle`s can be chained using the *+* operator.

 Le's create a bunch of styles:
 */

let centered = ComponentStyle<UIView>() { view in
  view.useFlexbox = true
  view.layout_justifyCotent = .center
  view.layout_alignSelf = .center
}

let h1 = ComponentStyle<UILabel>() { view in
  view.textAlignment = .center
  view.font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular)
}

let paragraph = ComponentStyle<UILabel>() { view in
  view.textAlignment = .center
  view.font = UIFont.systemFont(ofSize: 11.0, weight: UIFontWeightLight)
}

/*:
 We can also define functions that returns styles.
 */

func insets(_ margin: Float) -> ComponentStyle<UIView> {
  view.useFlexbox = true
  view.layout_marginAll = 4
}

func rounded(_ size: Float) -> ComponentStyle<UIView> {
  return ComponentStyle<UIView>() { view in
    view.layout_width = size
    view.layout_height = size
    view.layer.cornerRadius = CGFloat(size)/2
  }
}

/*:
 Finally, that's how we can use them in the body of our `construct` method.
 */

class FooComponentView: ComponentView {

  override func construct() -> NodeType {

    return Node<UIView>().configure({ view in
      view.apply(style: insets(4.0))
      view.backgroundColor = UIColor.A

    }).children([

      Node<UIView>().configure({ view in
        let style = CompoundComponentStyle(styles: [insets(2.0), rounded(64), centered])
        view.apply(style: style)
        view.backgroundColor = UIColor.B
      }),

      // another way to apply the style is to pass the style in to the constructor right away
      // - Note: In this case the style is going to be computed only at initialisation time.
      // This is the reason why the reuseIdentifier is mandatory - several views with the same style can be
      // reused by the infra efficiently.
      Node<UILabel>(reuseIdentifier: "h1", style: insets(3.0) + centered + h1).configure({ view in
        view.text = "John"
      }),

      Node<UILabel>(reuseIdentifier: "p", style: insets(1.0) + centered + paragraph).configure({ view in
        view.text = "Appleseed"
      })
    ])
  }
}
/*:
 Result:
 */
let component = FooComponentView()
component.renderComponent()

snapshot(component)

