import { Controller } from "@hotwired/stimulus"

// The note composer: a compact field that expands to the full editor, clears
// after a successful save, and submits on Cmd/Ctrl+Enter.
export default class extends Controller {
  static targets = ["form", "body", "toggle"]

  toggle() {
    this.#setExpanded(!this.element.classList.contains("expanded"))
    this.bodyTarget.focus()
  }

  // After a save, collapse so the new note isn't hidden behind a tall editor.
  reset(event) {
    if (!event.detail.success) return
    this.bodyTarget.value = ""
    this.#setExpanded(false)
    this.bodyTarget.focus()
  }

  key(event) {
    if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
      event.preventDefault()
      this.formTarget.requestSubmit()
    }
  }

  #setExpanded(expanded) {
    this.element.classList.toggle("expanded", expanded)
    this.toggleTarget.textContent = expanded ? "Collapse" : "Expand"
  }
}
