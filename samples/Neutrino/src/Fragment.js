ui.fragment.Counter = function(props, size) {
  return Node(UIView, null, { padding: 25,
                              backgroundColor: color(ui.color.coral),
                              flexDirection: column,
                              width: size.width }, [
    Node(UILabel, null, { text: "Counter" ,
                          font: font(ui.font.system, 16, ui.font.weight.bold) }, null),
    Node(UIButton, "button", { text: props.count.toString(),
                               height: 44,
                               backgroundColor: color(ui.color.blue),
                               padding: 12,
                               cornerRadius: 12,
                               font: font(ui.font.system, 14, ui.font.weight.regular) }, null)
  ])
}
