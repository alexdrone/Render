// private subfragments.

_CounterButton = (props) => {
  return UINode(UIButton, "button", {
      text: props.count.toString(),
      backgroundColorImage: palette.pink,
      padding: 8,
      cornerRadius: 12,
      textColor: palette.white,
      font: typography.mediumBold,
  }, null)
}

_CounterReloadLabel = () => {
  return UINode(UILabel, null, {
      text: "⌘ + R to reload the javascript fragment",
      margin: 8,
      textColor: palette.text,
      font: typography.smallBold,
  }, null)
}

_CounterBadge = (text) => {
  return UINode(UILabel, null, {
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

ui.fragment.Counter = (props, size) => {
  const badges = []
  for (let i = 0; i < props.count; i++) {
    badges.push(_CounterBadge((i+1).toString()))
  }

  const badgesContainer = UINode(UIView, null, {
      flexDirection: row,
      flexWrap: wrap,
      marginTop: 10,
  }, badges)

  return UINode(UIView, null, {
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

ui.fragment.TableHeader = (props, size) => {
  return UINode(UILabel, null, {
      text: 'Welcome to Render-Neutrino',
      font: typography.smallBold,
      textAlignment: ui.textAlignment.center,
      width: size.width,
      padding: 8,
      backgroundColor: palette.text,
      textColor: palette.white,
  }, null)
}
