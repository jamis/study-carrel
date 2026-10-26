// Giving focus back as something closes. Browsers ring whatever is focused after a key press, so sending focus to the
// button that opened a popover rings it even when it was opened with a tap or a shortcut and closed with Enter or Esc.

// The button a popover was opened from with the keyboard (Enter or Space on it), or null for a tap, a shortcut key or
// a script's click().
export const keyboardOpener = event =>
  event?.type === "click" && event.isTrusted && event.detail === 0 ? event.currentTarget : null

// Back to that button if there was one; otherwise just let go of focus left inside what closed.
export function giveBackFocus(opener, within) {
  if (opener) opener.focus()
  else if (within.contains(document.activeElement)) document.activeElement.blur()
}
