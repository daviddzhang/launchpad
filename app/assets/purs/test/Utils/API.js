exports.mock_ =
  (typeof global !== 'undefined' && global.CV && global.CV.mock) ||
  (() => null)

exports.unmock_ =
  (typeof global !== 'undefined' && global.CV && global.CV.unmock) ||
  (() => null)
