const palette = {
  green: color(0x70c1b3),
  pink: color(0xe0607e),
  text: color(0x1f5673),
  white: color(0xe4dfda),
}

const typography = {
  extraSmallBold: font(ui.font.system, 10, ui.font.weight.bold),  
  smallBold: font(ui.font.system, 12, ui.font.weight.bold),
  mediumBold: font(ui.font.system, 14, ui.font.weight.bold),
}

// private subfragments.

const _CounterButton = function(props) {
  return Node(UIButton, "button", {
      text: props.count.toString(),
      backgroundColor: palette.pink,
      padding: 8,
      cornerRadius: 12,
      textColor: palette.white,
      font: typography.mediumBold,
  }, null)
}

const _CounterReloadLabel = function() {
  return Node(UILabel, null, {
      text: "⌘ + R to reload the javascript fragment",
      margin: 8,
      textColor: palette.text,
      font: typography.smallBold,
  }, null)
}

const _CounterBadge = function(text) {
  return Node(UILabel, null, {
      backgroundColor: palette.white,
      width: 32,
      height: 32,
      cornerRadius: 16,
      margin: 4,
      text: text,
      textColor: palette.text,
      textAlignment: ui.textAlignment.center,
      font: typography.extraSmallBold,      
  }, null)
}

// the exported fragment.

ui.fragment.Counter = function(props, size) {

  const badges = []
  for (let i = 0; i < props.count; i++) {
    badges.push(_CounterBadge((i+1).toString()))
  }

  const badgesContainer = Node(UIView, null, {
      flexDirection: row,
      flexWrap: wrap,
      marginTop: 10,
  }, badges)

  return Node(UIView, null, {
      padding: 25,
      backgroundColor: palette.green,
      flexDirection: column,
      width: size.width,
  }, [
      _CounterReloadLabel(),
      _CounterButton(props),
      badgesContainer,
  ])
}
