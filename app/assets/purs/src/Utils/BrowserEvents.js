const React = require("react")

const documentEvents = ["selectionchange", "visibilitychange", "keyup"]
const windowEvents = ["resize", "mouseup", "mousemove", "hashchange", "popstate", "message"]

class BrowserEvents extends React.Component {
  constructor() {
    super()

    const mkHandlers = events => {
      let res = {}
      events.forEach(evtName => {
        res[evtName] = e => {
          const h = this.props[evtName]
          h && h(e)
        }
      })
      return res
    }

    this.handleWindow = mkHandlers(windowEvents)
    this.handleDocument = mkHandlers(documentEvents)
  }

  componentDidMount() {
    const attach = (obj, events) =>
      Object.keys(events).forEach(evtName =>
        obj.addEventListener(evtName, events[evtName])
      )

    attach(window, this.handleWindow)
    attach(document, this.handleDocument)
  }

  componentWillUnmount() {
    const detach = (obj, events) =>
      Object.keys(events).forEach(evtName =>
        obj.removeEventListener(evtName, events[evtName])
      )

    detach(window, this.handleWindow)
    detach(document, this.handleDocument)
  }

  render() {
    return null
  }
}

exports._browserEvents = BrowserEvents
