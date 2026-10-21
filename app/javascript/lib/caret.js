// Into an editor with the caret after what's written, to add to it.
export function focusAtEnd(editable) {
  editable.focus({ preventScroll: true })
  const range = document.createRange()
  range.selectNodeContents(editable)
  range.collapse(false)
  const selection = getSelection()
  selection.removeAllRanges()
  selection.addRange(range)
}
