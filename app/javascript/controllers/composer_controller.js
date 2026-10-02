import { Controller } from "@hotwired/stimulus"

// The note composer: clears after a successful save, Cmd/Ctrl+Enter submits.
export default class extends Controller {
  static targets = ["form", "body"]

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
