class InspectorController {
  constructor() {
    this.host = `http://localhost:8080`
    this.nodes = {}
    this.selectedId = null
  }
  fetchPayload() {
    let parseXml = function (xmlStr) {
      return (new window.DOMParser()).parseFromString(xmlStr, 'text/xml')
    }
    fetch(`${this.host}/inspect`)
      .then(response => response.text())
      .then(xmlString => parseXml(xmlString))
      .then(data => this.onDataChanged(data))
  }
  onDataChanged(data) {
    this.data = data
    let buffer = ``
    const nodeAttribute = (label, attr) => {
      let result = ``
      if (attr.length == 0) {
        return result
      }
      result += element({
        type: `span`,
        className: `node-label`
      })
      result += `  ${label}: `
      result += endElement(`span`)
      result += element({
        type: `span`,
        className: `node-value`
      })
      result += attr
      result += endElement(`span`)
      return result
    }
    let nil_id = 0
    // Traverse the xml nodes.
    const traverse = (nodes, level) => {
      if (nodes == null) {
        return
      }
      for (let i = 0; i < nodes.length; i++) {
        const node = nodes[i]
        if (node.nodeName == '#text') {
          continue;
        }
        // Store the node.
        const refStr = attr(node, `ref`)
        let ref = refStr.length > 0 ? refStr : `nil`
        ref = ref == `nil` ? `${ref}_${nil_id++}` : `0x…` + ref.substr(ref.length - 8)
        this.nodes[ref] = node
        // Recursively prints the representation.
        buffer += element({
          type: `div`,
          className: `node-container`,
          style: `margin-left:${level*8}px`,
          other: `data-id="${ref}"`
        })
        buffer += element({
          type: `span`,
          className: `node-arrow`,
          onclick: `Inspector.onToggleCollapse('${ref}')`
        })
        buffer += endElement('span')
        // Title.
        buffer += element({
          type: `span`,
          className: `node-title`,
          onclick: `Inspector.onNodeContainerClick('${ref}')`
        })
        buffer += node.nodeName
        buffer += endElement(`span`)
        buffer += nodeAttribute(`ref`, ref)
        buffer += nodeAttribute(`key`, attr(node, `key`))
        // Children nodes.
        buffer += element({
          type: `div`,
          className: `children`
        })
        const children = node.childNodes;
        traverse(children, level + 1)
        buffer += endElement(`div`)
        buffer += endElement(`div`)
      }
    }
    traverse(this.data.getElementsByTagName(`Application`), 0)
    document.getElementById(`components-tree`).innerHTML = buffer
    if (this.selectedId != null) {
      this.onNodeContainerClick(this.selectedId)
    }
  }
  onToggleCollapse(id) {
    console.log(id)
    const collapsed = `collapsed`
    const div = document.querySelectorAll(`div[data-id='${id}'] .children`)[0]
    div.classList.toggle(collapsed)
    const arrow = document.querySelectorAll(
      `div[data-id='${id}'] .node-arrow`)[0]
    arrow.classList.toggle(collapsed)
  }
  onNodeContainerClick(id) {
    const selected = `selected`
    for (let el of document.querySelectorAll(`.node-title`)) {
      el.classList.remove(selected)
    }
    let div = document.querySelectorAll(`div[data-id='${id}'] .node-title`)[0]
    div.classList.add(selected)
    const node = this.nodes[id]
    this.selectedId = id
    let buffer = ``
    buffer += element({
      type: `span`,
      className: `inspector-title`
    })
    buffer += inspectorValue(`reuseIdentifier`, node.nodeName)
    buffer += inspectorValue(`key`, attr(node, `key`))
    buffer += inspectorValue(`type`, attr(node, `type`))
    buffer += inspectorValue(`ref`, attr(node, `ref`))
    buffer += inspectorValue(`frame`, attr(node,`frame`))
    buffer += `<br/>`
    buffer += `Props`
    buffer += endElement(`span`)
    buffer += `<hr/>`
    let str = attr(node, `props`)
    if (str.length > 1) {
      str = str.replace(/__/g, '\"');
      buffer += jsonTree(JSON.parse(str))
    }
    buffer += `<br/>`
    buffer += `<br/>`
    buffer += element({
      type: `span`,
      className: `inspector-title`
    })
    buffer += `State`
    buffer += endElement(`span`)
    buffer += `<hr/>`
    str = attr(node, `state`)
    if (str.length > 1) {
      str = str.replace(/__/g, '\"');
      buffer += jsonTree(JSON.parse(str))
    }
    buffer += `<br/>`
    buffer += `<br/>`
    document.getElementById(`widget`).innerHTML = buffer
  }
}
let Inspector = new InspectorController()
Inspector.fetchPayload()

function jsonTree(obj) {
  let buffer = ``
  if (obj === undefined) {
    return buffer
  }
  buffer += element({
    type: `div`,
    className: `inspector-values`
  })
  for (var prop in obj) {
    if (!obj.hasOwnProperty(prop)) {
      continue;
    }
    buffer += inspectorValue(prop, obj[prop])
  }
  buffer += endElement(`div`)
  return buffer
}

function inspectorValue(key, value) {
  let buffer = ``
  if (key === undefined ||  value === undefined) {
    return buffer
  }
  buffer += element({
    type: `span`,
    className: `inspector-label`
  })
  buffer += key + `: `
  buffer += endElement(`span`)
  buffer += element({
    type: `span`,
    className: `inspector-value`
  })
  buffer += value
  buffer += endElement(`span`)
  buffer += '<br/>'
  return buffer
}

function attr(node, attr) {
  if (node.attributes[attr] !== undefined) {
    return node.attributes[attr].value
  }
  return ``
}

function element(args) {
  let result = `<${args.type}`
  if (args.className !== undefined) {
    result += ` class="${args.className}"`
  }
  if (args.style !== undefined) {
    result += ` style="${args.style}"`
  }
  if (args.onclick !== undefined) {
    result += ` onclick="${args.onclick}"`
  }
  if (args.other !== undefined) {
    result += ` ${args.other}`
  }
  result += `>`
  return result
}

function endElement(type) {
  return `</${type}>`
}
