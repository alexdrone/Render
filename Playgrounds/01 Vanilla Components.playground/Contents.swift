import UIKit
import XCPlayground
import Render

/*:
 ![logo](logo_small.png)
 # Vanilla Components
 
 **Render**'s building blocks are components (described in the protocol `ComponentViewType`).
 Any `UIView` object can be a component *(as long as it conforms to the above-cited protocol)*
 
 `BaseComponentView` is a good starting point if you wish to build your component in a traditional 
  way (with autolayout or `layoutSubview`) - but you don't have to inherit from any base class if you
  don't wish to.

  This is our super simple state:
  */
struct FooState: ComponentStateType {
    let text: String
}

/*:
 And this one below the component build with a old fashioned `layoutSubview`
 */
class VanillaComponentView: BaseComponentView {
    
    // we cast the state for convenience
    var fooState: FooState = FooState(text: "")
    
    // subview
    private let label = UILabel()
    private let dot: UIView = {
        let view = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 16, height: 16)))
        view.layer.cornerRadius = 8
        return view
    }()
    
    // This is used as entry point to initialize your component.
    // e.g. adding subviews / constraints and such.
    override func initalizeComponent() {
        backgroundColor = UIColor.A
        addSubview(dot)
        addSubview(label)
    }
    
    // Here we configure the view with the state passed as argument.
    override func renderComponent(size: CGSize) {
        super.renderComponent()
        label.text = self.fooState.text
        dot.backgroundColor = fooState.text == "Foo" ? UIColor.C : UIColor.B
        self.setNeedsLayout()
    }
    
    // And we layout the code (sigh!)
    override func layoutSubviews() {
        super.layoutSubviews()
        dot.frame.origin = CGPoint(x: 12, y: 12)
        label.frame.size = label.sizeThatFits(CGSize.undefined)
        label.frame.origin.x = CGRectGetMaxX(dot.frame) + 4
        label.center.y = dot.center.y
        frame.size.width = 96
        frame.size.height = dot.frame.size.height + 24
    }
}

/*:
 So now we can instantiate a `VanillaComponentView`.
 */

let vanillaComponent = VanillaComponentView()

/*:
 We set a state for the component and then we call `renderComponent`.
 */
vanillaComponent.fooState = FooState(text: "Foo")
vanillaComponent.renderComponent(CGSize.undefined)

snapshot(vanillaComponent)

vanillaComponent.fooState = FooState(text: "Bar")
vanillaComponent.renderComponent(CGSize.undefined)

snapshot(vanillaComponent)

