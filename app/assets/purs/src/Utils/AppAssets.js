exports.assetsRoot =
  (typeof CV !== "undefined" && CV.assetsRoot) ||
  (typeof global !== "undefined" && global.CV && global.CV.assetsRoot) ||
  "/"
