// Check on module load whether we can track performance to reduce overhead for
// when measurements are small.
const PERFORMANCE_ENABLED = typeof window !== "undefined" && window.performance

exports.mark = name => a => {
  if (PERFORMANCE_ENABLED) {
    window.performance.mark(`${name}:start`)
  }

  const result = a()

  if (PERFORMANCE_ENABLED) {
    window.performance.mark(`${name}:end`)
  }

  return result
}

exports.markStart = name => () => {
  if (PERFORMANCE_ENABLED) {
    window.performance.mark(`${name}:start`)
  }
}

exports.markEnd = name => () => {
  if (PERFORMANCE_ENABLED) {
    window.performance.mark(`${name}:end`)
  }
}

exports.trackTiming = ({ category, variable, value }) => () => {
  if (
    typeof window === "undefined" ||
    typeof window.CV === "undefined" ||
    typeof window.CV.Performance === "undefined"
  ) {
    if (typeof console !== "undefined" && typeof console.warn !== "undefined") {
      console.warn(
        "Performance:measureAndTrack: Missing `window.CV.Performance`. Tracking:",
        { category, variable, value }
      )
    }
    return
  }
  window.CV.Performance.trackTiming({ category, variable, value })
}

exports.measureDuration = name => () => {
  if (
    typeof window === "undefined" ||
    typeof window.CV === "undefined" ||
    typeof window.CV.Performance === "undefined"
  ) {
    return
  }
  return window.CV.Performance.measureDuration(`${name}:start`, `${name}:end`)
}

exports.markerStartTime_ = name => () => {
  if (typeof window === "undefined" || window.performance === "undefined") {
    return null
  }

  const entries = performance.getEntriesByName(`${name}:start`)
  if (!entries || entries.length === 0) {
    return null
  }

  return entries[0].startTime
}
