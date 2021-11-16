const React = require("react")
const Pusher = require("pusher-js")

exports.init = config => {
  if (typeof window === "undefined") {
    // If we're running under Node, we cannot initialize the real Pusher. First,
    // it's just a waste, but more importantly, it will create connections and
    // listeners, which will prevent the Node process from terminating,
    // effectively hanging the server-side rendering process.
    return new MockPusher()
  }

  if (config && config.key) {
    const options = {
      auth: { headers: { "X-CSRF-Token": config.authToken } },
      authEndpoint: config.authPath,
      cluster: config.cluster,
    }

    if (config.dev) {
      // Development local-only version, powered by `pusher-fake`
      Object.assign(options, {
        wsHost: config.dev.wsHost,
        wsPort: config.dev.wsPort,
        enabledTransports: ["ws"],
        forceTLS: false,
        disableStats: true,
      })
    }

    return new Pusher(config.key, options)
  }

  // See comments on MockPusher
  return (document.mockPusher = new MockPusher())
}

exports.subscribe = channelName => pusher => () =>
  pusher.subscribe(channelName)
exports.unsubscribe = channel => pusher => () =>
  pusher.unsubscribe(channel.name)
exports.trigger = channel => event => data => () => channel.trigger(event, data)
exports.socketId_ = pusher => () =>
  pusher.connection && pusher.connection.socket_id

class PusherChannelListener extends React.Component {
  constructor(props) {
    super(props)
    this.state = {}
  }

  render() {
    return null
  }

  componentDidMount() {
    this.rebind(this.props)
  }

  UNSAFE_componentWillReceiveProps(props) {
    this.rebind(props)
  }

  componentWillUnmount() {
    this.unbind()
  }

  rebind({ channel, event }) {
    const bound = this.bound
    if (!bound || bound.channel !== channel || bound.event !== event) {
      this.unbind()
      const handler = dta => this.props.onEvent(dta)
      channel.bind(event, handler)
      this.bound = { channel, event, handler }
    }
  }

  unbind() {
    if (!this.bound) return
    const { channel, event, handler } = this.bound
    channel.unbind(event, handler)
  }
}

exports.channelListener_ = PusherChannelListener

// ----------------------------------------------------------------------------------
// MockPusher is used in unit tests, and its innards are not just random, but
// relied upon in the Ruby test code in spec/features/livestream/watch_spec.rb
//
// We probably could use `pusher-fake` instead of this, but it was already
// implemented this way when I got here, and I didn't want to allow scope creep
// on this change.
// ----------------------------------------------------------------------------------

function MockPusher() {
  this.channels = []
  this.subscribe = function(channelName) {
    const newChannel = new MockChannel(channelName)
    this.channels.push(newChannel)
    return newChannel
  }
  this.channelNames = function() {
    return this.channels.map(c => c.name)
  }
}

function MockChannel(name) {
  this.name = name
  this.handlers = {}
  this.triggered = []
  this.bind = function(eventName, handler) {
    this.handlers[eventName] = handler
  }
  this.trigger = function(eventName, eventData) {
    this.triggered.push({ eventName, eventData })
  }
}
