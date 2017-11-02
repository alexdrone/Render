ui.style.Padding = function(props, size) {
  return {
      padding: 25,
      backgroundColor: color(ui.color.coral)
  }
}

ui.fragment.PaddedLabel = function(props, size) {
  return Node(UIView, null, {
      padding: 25,
      backgroundColor: color(ui.color.coral),
      width: size.width
  }, [
      Node(UILabel, null, {
          text: props.text,
          font: font(ui.font.system, 12, ui.font.weight.regular)
      }, null)
  ])
}