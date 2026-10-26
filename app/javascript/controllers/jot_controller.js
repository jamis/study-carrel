import { Controller } from "@hotwired/stimulus"

// An idea written in place on the Kept page: the "+ Jot an idea" slip, or an idea pressed to write it again. Opening
// it puts the field where the slip (or the idea) was. Enter or a tap away keeps it, Shift+Enter is a new line, Esc
// leaves it as it was. The page draws itself again (a morph) once it's kept, closed.
export default class extends Controller {
  static targets = ["shown", "form", "field", "left"]
  static values = { key: String }

  // The slip's own key (n), from anywhere on the page but a field.
  key(event) {
    if (event.key !== this.keyValue || event.metaKey || event.ctrlKey || event.altKey) return
    if (event.target.closest("input, textarea, select, [contenteditable]")) return
    event.preventDefault()
    this.open()
  }

  open() {
    this.before = this.fieldTarget.value
    this.done = false
    this.shownTarget.hidden = true
    this.formTarget.hidden = false
    const field = this.fieldTarget
    field.focus()
    field.setSelectionRange(field.value.length, field.value.length)
    this.count()
  }

  fieldKey(event) {
    if (event.key === "Enter" && !event.shiftKey && !event.isComposing) {
      event.preventDefault()
      this.keep()
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.leave({ refocus: true })
    }
  }

  blur() {
    if (!this.done) this.keep()
  }

  // The characters left, only near the end.
  count() {
    const left = this.fieldTarget.maxLength - this.fieldTarget.value.length
    this.leftTarget.textContent = left <= 40 ? `${left} left` : ""
    this.leftTarget.classList.toggle("near", left <= 20)
  }

  // Nothing written, or nothing changed, is nothing to keep; an idea emptied out stays as it was (Remove is for that).
  keep() {
    const words = this.fieldTarget.value.trim()
    if (!words || words === this.before.trim()) return this.leave()
    this.done = true
    this.formTarget.requestSubmit()
  }

  // Esc gives the keyboard back to the slip (or the idea); a tap away leaves it where it went.
  leave({ refocus = false } = {}) {
    this.done = true
    this.fieldTarget.value = this.before
    this.formTarget.hidden = true
    this.shownTarget.hidden = false
    if (refocus) this.shownTarget.focus()
  }
}
