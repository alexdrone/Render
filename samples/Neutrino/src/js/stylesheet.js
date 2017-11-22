// STYLE VARIABLES

// These can be referred within your js *fragments* or *style* definitions
// e.g. *backgroundColor: palette.green* or from your native code by using the
// *UIContext* javascript bridge.
// e.g. *let color: UIColor? = context.jsBridge.variable(namespace: .palette, name: "green")*
// The variables defined in the *palette*, *typography*, *flags*, and *constants*
// objects are pre-fetched from Render.
//
// N.B. If you want hot-reload (⌘ + R) enabled you first need to:
// - run ./tools/watch-js.sh JS_FILE_DIRECTORY
// - Set *NSAppTransportSecurity* in Info.plist to *NSAllowsArbitraryLoads* for your
//   debug build (You can use a preprocessed Info.plist and wrap the configuration in
//   #if DEBUG ... #endif).
//
// Palette variables to be used across the app.
// e.g. *red: color(ui.color.coral)* or *white: color(0xffffff)*.
// Note - The color alpha component can be specified through an optional second argument
// e.g. *color(0xaabbcc, 0xf0)*.
const palette = {
  navigationBar: color(0x151416),
  primaryAccent: color(0x151416),  
  primary: color(0x252427),
  primaryText: color(0x37353A),
  secondary: color(0x302E31),
  accent: color(0x41403C),
  accentText: color(0x56554E),
  green: color(0x5B654F),
  pink: color(0x5F4A53),
  text: color(0x0d1b1e),
  white: color(0xeaeaea),
  blue: color(0x413D4C),
}

// The fonts used in your app.
// e.g. *medium: font('Avenir Next', 20)*
// The system font is accessible through *ui.font.system*.
// Note - The font weight can be specified as an optional third argument by accessing the
// *ui.font.weight* object.
const typography = {
  extraSmallBold: font(ui.font.system, 10, ui.font.weight.bold),
  smallBold: font(ui.font.system, 12, ui.font.weight.bold),
  small: font(ui.font.system, 12, ui.font.weight.regular),
  medium: font(ui.font.system, 16, ui.font.weight.regular),
  mediumBold: font(ui.font.system, 16, ui.font.weight.bold),
}

// App UI configuration flags.
// e.g. *shouldShowNewUI: true* or *version: 2*.
const flags = { }

// General leyout constants.
// e.g. *defaultButtonWidth: 44* or *avatarSize: size(128, 128)*.
const constants = { }

// STYLES

// Styles can be referred from js fragment nodes
// e.g. *Node(UIView, 'myKey', ui.style.MyStyle(), [])* more styles can be combined by using
// the *Object.assing* api.
// You can apply a js style to a view from your native node defintion by invoking the javascript
// bridge available in your context.
// e.g. *context.jsBridge.resolveStyle(view: view, function: "MyStyle", props: props, size: size)*

/*
 ui.style.MyStyle = function(args, size) {
   return {
     backgroundColor: palette.green,
     flexDirection: row,
     padding: 4
   }
 }
 */

// FRAGMENTS

/*
 ui.fragment.MyFragment = function(props, size) {
   return Node("UIView", "myKey", { backgroundColor: color(0xffffff) }, [
     Node("UILabel", null, {text: props.text}, null)
   ])
 }
 */
