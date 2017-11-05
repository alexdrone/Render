// private subfragments.

const _CounterButton = function(props) {
  return Node(UIButton, "button", {
      text: props.count.toString(),
      backgroundColorImage: palette.pink,
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
