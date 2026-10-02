import { Controller } from "@hotwired/stimulus"

// The notes panel: a side card on desktop, a bottom sheet on phones.
export default class extends Controller {
  static targets = ["label", "handle"]

  toggle() {
    this.#set(!this.element.classList.contains("open"))
  }

  escape() {
    if (!this.element.classList.contains("open")) return
    this.#set(false)
    this.handleTarget.focus()
  }

  #set(open) {
    this.element.classList.toggle("open", open)
    this.labelTarget.textContent = open ? "Close ▾" : "Notes ▴"
    this.handleTarget.setAttribute("aria-expanded", open)
  }
}
