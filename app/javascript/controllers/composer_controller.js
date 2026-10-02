import { Controller } from "@hotwired/stimulus"

// The note composer: a compact field that expands to the full editor, clears
// after a successful save, and submits on Cmd/Ctrl+Enter.
export default class extends Controller {
  static targets = ["form", "body", "toggle"]

  toggle() {
    const expanded = this.element.classList.toggle("expanded")
    this.toggleTarget.textContent = expanded ? "Collapse" : "Expand"
    this.bodyTarget.focus()
  }

  reset(event) {
    if (!event.detail.success) return
    this.bodyTarget.value = ""
    this.bodyTarget.focus()
  }

  key(event) {
    if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
      event.preventDefault()
      this.formTarget.requestSubmit()
    }
  }
}
