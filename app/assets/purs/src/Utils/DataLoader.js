const React = require("react")

class DataLoader extends React.Component {
  componentDidMount() {
    const xhr = new XMLHttpRequest()
    xhr.open("GET", this.props.url)
    xhr.addEventListener("progress", this.props.onProgress, false)
    xhr.addEventListener("load", event => {
      if (xhr.status !== 200) {
        this.props.onError(`Unexpected XHR status: ${xhr.status}`)
        return
      }
      try {
        const json = JSON.parse(xhr.response)
        this.props.onComplete(json)
      } catch (error) {
        this.props.onError(
          `Failed to parse response as JSON: ${error.message || error.toString}`
        )
      }
    })
    xhr.addEventListener("error", event => {
      this.props.onComplete("XHR error:")
    })
    xhr.send()

    this.xhr = xhr
  }

  componentWillUnmount() {
    if (!this.xhr) {
      return
    }

    this.xhr.abort()
    this.xhr = null
  }

  render() {
    return null
  }
}

exports._dataLoader = DataLoader
