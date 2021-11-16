exports.promise = f => () =>
  new Promise((success, error) => {
    var succF = s => () => success(s)
    var failF = s => () => error(s)

    // This indicates the aff was wrong?
    try {
      f(succF)(failF)()
    } catch (e) {
      error(e)
    }
  })

exports.thenImpl = promise => errCB => succCB => () =>
  promise.then(succCB, errCB)

exports.isError = x => x instanceof Error

exports.safeToString = x =>
  x === null ? "null" : typeof x === "undefined" ? "undefined" : x.toString()
