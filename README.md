<p align="center">
![Render Logo](Doc/logo.png)


[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Build](https://img.shields.io/badge/build-passing-green.svg?style=flat)](#)
[![Platform](https://img.shields.io/badge/platform-ios-lightgrey.svg?style=flat)](#)
[![Build](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://opensource.org/licenses/MIT)

*React-inspired swift library for writing UIKit UIs which are functions of their state.*

#Why

**Render** lets us write our UIs as a pure function of their state.


Right now we write UIs by poking at them, manually mutating their properties when something changes, adding and removing views, etc. This is fragile and error-prone. Some tools exist to lessen the pain, but they can only go so far. UIs are big, messy, mutable, stateful bags of sadness.

**Render** let us describe our entire UI for a given state, and then it does the hard work of figuring out what needs to change. It abstracts all the fragile, error-prone code out away from us. 

## Installation

### Carthage

**Render** layout engine is based on [flexbox](www.github.com/alexdrone/FlexboxLayout).

To install Carthage, run (using Homebrew):

```bash
$ brew update
$ brew install carthage
```

Then add the following line to your `Cartfile`:

```
github "alexdrone/Render" "master"    
```

#What's it like?

This is what a component (and its state) would look like:

<p align="center">
<img src="Doc/render.jpg" width="192">


```swift

struct Album: ComponentStateType {
	let title: String
	let artist: String
	let cover: UIImage  
}

class AlbumComponentView: ComponentView {
    
    // the component state.
    var album: Album? {
        return self.state as? Album
    }
    
    // View as function of the state.
    override func construct() -> ComponentNodeType {
            
        return ComponentNode<UIView>().configure({ view in
        		view.style.flexDirection = .Column
            	view.backgroundColor = UIColor.blackColor()

        }).children([
            
            ComponentNode<UIImageView>().configure({ view in
				view.image = self.album?.cover
				view.style.dimensions = (self.parentSize.width, self.parentSize.width)
            }),
            
            ComponentNode<UIView>().configure({ view in
                view.style.flexDirection = .Column
                view.style.margin = (8.0, 8.0, 8.0, 8.0, 0.0, 0.0)
                
            }).children([
                
                ComponentNode<UILabel>().configure({ view in
                    view.text = self.album?.title ?? "None"
                    view.font = UIFont.systemFontOfSize(18.0, weight: UIFontWeightBold)
                    view.textColor = UIColor.whiteColor()
                }),
                
                ComponentNode<UILabel>().configure({ view in
                    view.text = self.album?.artist ?? "Uknown Artist"
                    view.font = UIFont.systemFontOfSize(12.0, weight: UIFontWeightLight)
                    view.textColor = UIColor.whiteColor()
                })
            ])
        ])
    }
    
}

```
