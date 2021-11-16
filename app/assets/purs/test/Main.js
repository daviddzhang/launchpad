const jsdom = require('global-jsdom')

// This needs to run before React, which is why it’s being run globally in the
// FFI. See https://enzymejs.github.io/enzyme/docs/guides/jsdom.html for more
// info.
jsdom()

exports._configureJsDomViaFfi = null

const mockDictionary = {}

global.CV = global.CV || {}

// For a given API path name, e.g. `“schools_lists_add_path”`, produces a
// function that takes the right number of curried parameters (this number is
// determined on PS side and passed in here), and then returns an Aff, which,
// only when executed, but no earlier, looks up a mocked function for this API
// path in the mock dictionary and passes all the accumulated parameters to it,
// and returns its result.
global.CV.apiEndpoint = ({ delegateAff, numParameters, name, continuation }) => {
  const mkCurriedFn = (remainingParameters, parametersSoFar) => {
    if (remainingParameters > 0) {
      // Collect another parameter `x` and recur
      return x => mkCurriedFn(remainingParameters - 1, [...parametersSoFar, x])
    } else {
      // No more parameters => return an Aff, which, when executed, will look
      // for a mocked function in the dictionary and pass all accumulated
      // parameters to it, then return its result.
      //
      // We have to use the `delegateAff` function that the PS side passed to
      // us, because we have to return an `Aff`, but we can't construct one in
      // JS. So instead, we construct an `Effect` (which in JS looks like just a
      // function) and give it to `delegateAff`, which creates an `Aff` out of
      // it.
      return delegateAff(() => {
        const mock = mockDictionary[name]
        if (!mock) {
          throw new Error(
            `API request '${name}' is executing, but there is no mock for it. ` +
            "Either the test case never mocked it, or the test case ended before " +
            "async messages were allowed to finish executing."
          )
        }

        // Here we rely on the fact that the mocked function has the exact same
        // signature, and thus the same number of parameters, as the real API
        // function. This is enforced on PS side via the type signature of
        // `mockApi`.
        return callCurriedFn(mock, parametersSoFar)
      })
    }
  }

  const callCurriedFn = (fn, parameters) => {
    if (parameters.length > 0) {
      // There are parameters => apply next parameter and recur
      return callCurriedFn(fn(parameters[0]), parameters.slice(1))
    } else {
      // No more parameters => `fn` is not actually a function, but the ultimate result.
      return fn
    }
  }

  const res = mkCurriedFn(numParameters, [])
  res.__mockPath = name
  return res
}

// Adds the API function to the `mockDictionary`. Since the input is the result
// of `apiEndpoint_`, it will always have a `__mockPath` field on it.
global.CV.mock = (api, f) => {
  mockDictionary[api.__mockPath] = f
}

// Removes the API function from the `mockDictionary`.
global.CV.unmock = api => {
  delete mockDictionary[api.__mockPath]
}
