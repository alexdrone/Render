class InspectorController {
  constructor() {
    this.host = `http://localhost:8080`
    this.nodes = {}
    this.selectedRef = null
    this.refs = []
    this.collapsed = {}
    //window.setInterval(() => { this.fetchPayload() }, 1000)
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
    let newRefs = []
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
        ref = ref == `nil` ? `${ref} (${nil_id++})` : ref
        if (refStr.length > 0) {
          newRefs.push(ref)
        }
        const key = attr(node, `key`)
        this.nodes[ref] = node
        this.nodes[key] = node
        // Recursively prints the representation.
        buffer += element({
          type: `div`,
          className: `node-container`,
          style: `margin-left:${level*8}px`,
          other: ` data-ref="${ref}"`
        })
        buffer += element({
          type: `span`,
          className:  this.collapsed[ref] ? `node-arrow collapsed` : `node-arrow`,
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
        if (!ref.startsWith(`nil`)) {
          buffer += nodeAttribute(`ref`, `0x…` + ref.substr(ref.length - 4))
        }
        buffer += nodeAttribute(`key`, key)
        // Children nodes.
        buffer += element({
          type: `div`,
          className: this.collapsed[ref] ? `children collapsed` : `children`
        })
        const children = node.childNodes;
        traverse(children, level + 1)
        buffer += endElement(`div`)
        buffer += endElement(`div`)
      }
    }
    traverse(this.data.getElementsByTagName(`Application`), 0)
    document.getElementById(`components-tree`).innerHTML = buffer
    if (this.selectedRef != null) {
      this.onNodeContainerClick(this.selectedRef)
    }

    let added = 0
    let removed = 0
    for (let ref of newRefs) {
      if (this.refs.indexOf(ref) == -1) added++
    }
    for (let ref of this.refs) {
      if (newRefs.indexOf(ref) == -1) removed++
    }
    this.refs = newRefs
    let reused = newRefs.length - added
    document.getElementById(`status`).innerHTML = `${reused} REUSED, ${added}+, ${removed}-`
  }
  onToggleCollapse(ref) {
    const collapsed = `collapsed`
    const div = document.querySelectorAll(`div[data-ref='${ref}'] .children`)[0]
    div.classList.toggle(collapsed)
    const arrow = document.querySelectorAll(
      `div[data-ref='${ref}'] .node-arrow`)[0]
    arrow.classList.toggle(collapsed)    
    this.collapsed[ref] = !(this.collapsed[ref] || false)
  }
  onNodeContainerClick(ref) {
    const selected = `selected`
    for (let el of document.querySelectorAll(`.node-title`)) {
      el.classList.remove(selected)
    }
    let div = document.querySelectorAll(`div[data-ref='${ref}'] .node-title`)[0]
    div.classList.add(selected)
    const node = this.nodes[ref]
    this.selectedRef = ref
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
