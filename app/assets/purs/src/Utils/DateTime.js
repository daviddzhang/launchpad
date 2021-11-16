exports.parseAsLocalTime_ = ({ just, nothing }) => s => {
  try {
    const d = new Date(s)
    if (isNaN(d.getTime())) {
      return nothing
    } else {
      return just(d)
    }
  } catch (_) {
    return nothing
  }
}

exports.jsDateToRecord_ = d => {
  return {
    year: d.getFullYear(),
    month: d.getMonth(),
    day: d.getDate(),
    hour: d.getHours(),
    minute: d.getMinutes(),
    second: d.getSeconds(),
    millisecond: d.getMilliseconds(),
  }
}

exports.jsDateNow_ = () => new Date()

exports.jsPageLoadLocalTime_ = (() => {
  let cached = new Date()

  if (typeof window !== "undefined") {
    // When running in browser, we always return the same value, which was
    // initialized at page load. This is the time of current page load. Just
    // what it says on the tin.
    return () => cached
  } else {
    // When running in Node, we can't return the same once-initialized value,
    // because the same Node process may keep running for a very long time
    // (days), so any differences that SSRed UI might calculate based on this
    // value will keep shifting. Instead, we try to make each individual SSR
    // pass feel like it's been "just loaded". To do this, we keep the return
    // value always within one second of the actual "now": when the cached value
    // drifts by more than a second, we reset it to "now". We don't just return
    // "now" itself every time, so as to keep this value semi-stable.
    return () => {
      const now = new Date()
      if (now - cached > 1000) { cached = now }
      return cached
    }
  }
})();

// This somewhat hacky implementation was lifted from Rails's `local_time`
// package, client-side code of which is written in CoffeScript, located at:
// https://github.com/basecamp/local_time/blob/5edd54f5e1e79bcb8e512ba1f89077241f55fc8c/lib/assets/javascripts/src/local-time/helpers/strftime.coffee#L40-L57
// It relies on the fact that calling `.toString()` on a JS `Date` object will
// return a string that contains the timezone, but this timezone is not always
// in a consistent abbreviated format, hence all the regexes.
exports.localTimeZoneName = (() => {
  const s = new Date().toString()

  // Sun Aug 30 2015 10:22:57 GMT-0400 (EDT)
  let name = (s.match(/\(([\w\s]+)\)$/) || [])[1]
  if (name) {
    if (/\s/.test(name)) {
      // Sun Aug 30 2015 10:22:57 GMT-0400 (Eastern Daylight Time)
      return (name.match(/\b(\w)/g) || []).join("")
    } else {
      // Sun Aug 30 2015 10:22:57 GMT-0400 (EDT)
      return name
    }
  }

  // Sun Aug 30 10:22:57 EDT 2015
  name = (s.match(/(\w{3,4})\s\d{4}$/) || [])[1]
  if (name) return name

  // "Sun Aug 30 10:22:57 UTC-0400 2015"
  name = (s.match(/(UTC[\+\-]\d+)/) || [])[1]
  if (name) return name

  // "Sun Aug 30 2015 10:22:57 GMT-11:00"
  name = (s.match(/(GMT[\+\-]\d+)/) || [])[1]
  if (name) return name

  return ""
})()
