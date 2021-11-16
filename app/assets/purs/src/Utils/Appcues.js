exports.show_ = (id, onError) => {
  if (typeof window.Appcues === "undefined") {
    return onError("Attempted to call Appcues.show, but Appcues is not defined")
  }

  if (typeof window.Appcues.show !== "function") {
    return onError("Attempted to call Appcues.show, but Appcues.show is not defined")
  }

  window.Appcues.show(id)
}
