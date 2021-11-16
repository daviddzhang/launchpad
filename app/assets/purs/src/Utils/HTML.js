exports.documentVisibilityState = () => document.visibilityState == "visible"

exports.elementFromPoint_ = (x, y) => document.elementFromPoint(x, y)

// A bit of a hacky way of determining x/y coordinates of a textarea's caret. To
// do this, we create a dummy <div> that has the same style (here by proxy of
// class) and the same size as the textarea, then give it text content equal to
// portion of textarea's value before the caret, then append a dummy <span> at
// the end, and finally read out the span's coordinates.
//
// The idea is that, if all the styles are the same between the div and the
// textarea, the text will flow and wrap in the exact same way, and the location
// of the span will be equal to that of the caret.
//
// It blows my mind that there is still, in 2021, no standard way of doing this,
// but this appears to be the common wisdom. I checked a few places on the
// Internet, and all of them either do this or don't use a textarea at all,
// instead utilizing a custom-built rich text editor.
exports.textAreaCaretCoordinates = textarea => () => {
  const div = document.createElement("div")
  div.className = textarea.className
  div.style.whiteSpace = "pre-wrap"
  div.style.position = "absolute"
  div.style.top = -10000
  div.style.width = textarea.clientWidth + "px"
  div.style.height = textarea.clientHeight + "px"

  const span = document.createElement("span")
  span.innerHTML = "&nbsp;"
  span.style.width = "1px"

  div.textContent = (textarea.value || "").substring(0, textarea.selectionStart)
  div.appendChild(span)
  document.body.appendChild(div)

  const res = { x: span.offsetLeft, y: span.offsetTop }
  document.body.removeChild(div)

  return res
}

exports.scrollToTop = function() {
  if (typeof window === "undefined") {
    return
  }

  window.scrollTo(0, 0)
}
