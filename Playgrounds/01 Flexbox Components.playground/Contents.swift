import UIKit
import XCPlayground
import Render

/*:
 ![logo](logo_small.png)
 # Flexbox Components
 
 Despite virtually any `UIView` object can be a component (as long as it conforms to the above-cited protocol),
 **Render**'s core functionalities are exposed by the two main Component base classes: `ComponentView` and `StaticComponentView` 
 (optimised for components that have a static view hierarchy).
 
 **Render** layout engine is based on [FlexboxLayout](https://github.com/alexdrone/FlexboxLayout).
 Every view have a `style` property that defines the flexbox properties for the associated node.
 
 Learn more about [Flexbox](http://www.w3.org/TR/css-flexbox-1/).

 # Partials

 Before diving in a full-blown component let's define an helper function that returns a partial (or a node)
 for a component.
 
 The function below creates a `UIButton` node (`ComponentNode` can be instanciated with any view type, even custom ones).
 When we want to have a custom initialisation for a node we just need to provide a `initClosure` to `ComponentNode`.
 Additionaly we define a `reuseIdentifier` - This is not mandatory, but since we have a custom init closure, this will help 
 Render's infra to reuse view of the same kind.
 */
func DefaultButton() -> Node<UIButton> {
    
    // when you construct a node with a custom initClosure setting a reuseIdentifier
    // helps the infra recycling that view.
    return Node<UIButton>(reuseIdentifier: "DefaultButton", initClosure: {
        let view = UIButton()
        view.useFlexBox = true
        view.layout_minWidth = 64
        view.layout_minHeight = 64
        view.layout_alignSelf = .center
        view.layout_justifyContent = .center
        view.setTitleColor(UIColor.A, for: .normal)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightLight)
        view.layer.cornerRadius = 32
        return view
    })
}
/*: Let's see what our button looks like. */
let button = DefaultButton().configure({ view in
    view.setTitle("  HELLO WORLD  ", for: .normal)
})
button.render(CGSize.undefined)

snapshot(button.renderedView!)

/*:
 # ComponentView
 
 This is our super simple state for our component:
*/
struct FooState: ComponentStateType {
    let text: String
    let expanded: Bool
}

/*:
 Below we implement our component as subclass of `ComponentView`.
 
 The view description is defined by the `construct()` method.
 
 `ComponentNode<T>` is an abstraction around views of any sort that knows how to build, 
 configure and layout the view when necessary.
 
 Every time `renderComponent()` is called, a new tree is constructed, compared to the existing 
 tree and only the required changes to the actual view hierarchy are performed - *if you have a static 
 view hierarchy, you might want to inherit from `StaticComponentView` to skip this part of the rendering* .
 Also the `configure` closure passed as argument is re-applied to every view defined in the `construct()` 
 method and the layout is re-computed based on the nodes' flexbox attributes.
 */

class FooComponentView: ComponentView {
    
    // we cast the state for convenience
    var fooState: FooState = FooState(text: "", expanded: false)

    override func construct() -> ComponentNodeType {

        
        return Node<UIView>().configure({ view in
            view.useFlexbox = true
            view.layout_flexDirection = self.fooState.expanded ? .column : .row
            view.backgroundColor = UIColor.A
        }).children([
            
            Node<UIView>().configure({ view in
                let size: Float = self.fooState.expanded ? 128 : 32
                view.useFlexbox = true
                view.layout_width = size
                view.layout_height = size
                view.backgroundColor = UIColor.D
                view.layer.cornerRadius = CGFloat(size)/2
            }).children([
            
                // this node is going to be part of the view hierarchy only when
                // the condition 'self.fooState.expanded' is true.
                when(self.fooState.expanded,
                Node<UIView>().configure({ view in
                    view.layout_useFlexbox = true
                    view.layout_flexGrow = 1
                    view.layout_alignSelf = .stretch
                    view.layout_justifyContent = .center
                        
                }).children([
                    
                    //This is just a pure function initializing a button with a style
                    DefaultButton().configure({ view in
                        view.setTitle(self.fooState.text, for: .normal)
                    }),
                ]))
            ]),
            
            // simmetrically, this node is going to be part of the view hierarchy only when
            // the condition 'self.fooState.expanded' is false.
            when(!self.fooState.expanded,
            Node<UILabel>().configure({ view in
                view.useFlexbox = true
                view.layout_alignSelf = .center
                view.layout_minWidfth = 96
                view.layout_flexGrow = 1
                view.textAlignment = self.fooState.expanded ? .center : .left
                view.text = self.fooState.text
                if self.fooState.expanded {
                    view.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightBold)
                } else {
                    view.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightLight)
                }
            }))
        ])
    }
}
/*:
 So now we can instantiate a `FooComponentView`.
 */
let component = FooComponentView()
component.fooState = FooState(text: "Foo", expanded: false)
component.renderComponent()

snapshot(component)

component.fooState = FooState(text: "Foo", expanded: true)
component.renderComponent()

snapshot(component)

/*:
 # StaticComponentView
 
 The first component we implemented before could have been implemented with a static view hierarchy
 (by hiding/showing the views rather then removing/adding them from/to the view hierarchy).
 
 `StaticComponentView` views have a more performant `renderComponent` method.
  
 This is what a static version of the previous component would look like
 */
class StaticFooComponentView: StaticComponentView {
    
    // we cast the state for convenience
    var fooState: FooState = FooState(text: "", expanded: false)
    
    override func construct() -> ComponentNodeType {

        return Node<UIView>().configure({ view in
            view.layout_useFlexbox = true
            view.layout_flexDirection = self.fooState.expanded ? .column : .row
            view.backgroundColor = UIColor.A
        }).children([
            
            Node<UIView>().configure({ view in
                let size: Float = self.fooState.expanded ? 128 : 32
                view.layout_useFlexbox = true
                view.layout_minWidth = size
                view.layout_minHeight = size
                view.backgroundColor = UIColor.D
                view.layer.cornerRadius = CGFloat(size)/2
            }).children([
                

                Node<UIView>().configure({ view in
                    
                    // this node is going to be visible only when
                    // the condition 'self.fooState.expanded' is true.
                    view.isHidden = !self.fooState.expanded
                    view.useFlexbox = true
                    view.layout_flexGrow = 1
                    view.layout_alignSelf = .center
                    view.layout_justifyContent = .center
                
                }).children([
                        
                        //This is just a pure function initializing a button with a style
                        DefaultButton().configure({ view in
                            view.setTitle(self.fooState.text, for: .normal)
                        }),
                ])
            ]),
            

            Node<UILabel>().configure({ view in
                
                // simmetrically, this node is going to be visible only when
                // the condition 'self.fooState.expanded' is false.
                view.isHidden = self.fooState.expanded

                view.useFlexbox = true
                view.layout_alignSelf = .center
                view.layout_minWidth = 96
                view.layout_flexGrow = 1
                view.textAlignment = self.fooState.expanded ? .center : .left
                view.text = self.fooState.text
                if self.fooState.expanded {
                    view.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightBold)
                } else {
                    view.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightLight)
                }
            })
        ])
    }
}

/*: As you can see the result is exactly the same */

let staticComponent = StaticFooComponentView()
staticComponent.fooState = FooState(text: "Foo", expanded: false)
staticComponent.renderComponent()

snapshot(staticComponent)

staticComponent.fooState = FooState(text: "Foo", expanded: true)
staticComponent.renderComponent()

snapshot(staticComponent)

  
