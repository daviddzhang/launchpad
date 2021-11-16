exports.pathInfo_ =
  (typeof CV !== "undefined" && CV.pathInfo) ||
  (typeof global !== "undefined" && global.CV && global.CV.pathInfo) ||
  (_ => null)

exports.apiEndpoint_ = (path, k) => {
  // Checking `CV.apiEndpoint` and `global.CV.apiEndpoint` is deferred so that
  // `global.CV.apiEndpoint` is set before the check happens since this is
  // called at the top level of a module.
  const apiEndpoint =
    (typeof CV !== "undefined" && CV.apiEndpoint) ||
    (typeof global !== "undefined" && global.CV && global.CV.apiEndpoint)

  if (!apiEndpoint) console.error("Missing `CV.apiEndpoint` function")
  return apiEndpoint && apiEndpoint(path, k)
}
