exports.trackEvent = function(name) {
  return function(properties) {
    return function() {
      if (typeof heap === "undefined") {
        return
      }

      heap.track(name, properties)
    }
  }
}
