import { Controller } from "@hotwired/stimulus"

// The note composer: a compact field that expands to the full editor, clears
// after a successful save, and submits on Cmd/Ctrl+Enter.
export default class extends Controller {
  static targets = ["form", "body", "toggle", "error"]

  toggle() {
    this.#setExpanded(!this.element.classList.contains("expanded"))
    this.bodyTarget.focus()
  }

  // After a save, collapse so the new note isn't hidden behind a tall editor.
  reset(event) {
    if (!event.detail.success) return this.#showError(event.detail.fetchResponse?.statusCode)
    this.clearError()
    this.bodyTarget.value = ""
    this.#setExpanded(false)
    this.bodyTarget.focus()
  }

  clearError() {
    this.errorTarget.hidden = true
  }

  key(event) {
    if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
      event.preventDefault()
      this.formTarget.requestSubmit()
    }
  }

  // A 422 means the note was empty; anything else (offline, server error) is worth retrying.
  #showError(status) {
    this.errorTarget.textContent = status === 422 ? "Write a note before adding it." : "Couldn't save that note. Please try again."
    this.errorTarget.hidden = false
  }

  #setExpanded(expanded) {
    this.element.classList.toggle("expanded", expanded)
    this.toggleTarget.textContent = expanded ? "Collapse" : "Expand"
  }
}
