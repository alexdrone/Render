
ui.style.padding = function(props, size) {
  return { padding: 25, 
           backgroundColor: color(0xa0ffff, 0xff) }
}

ui.fragment.paddedLabel = function(props, size) {
  return Node(UIView, null, ui.style.padding(props, size), [
    Node(UILabel, null, { text: props.text }, [])
  ])
}
