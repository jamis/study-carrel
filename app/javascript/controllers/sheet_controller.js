import { Controller } from "@hotwired/stimulus"

// The notes panel: a side card on desktop, a bottom sheet on phones.
export default class extends Controller {
  static targets = ["label"]

  toggle() {
    const open = this.element.classList.toggle("open")
    this.labelTarget.textContent = open ? "Close ▾" : "Notes ▴"
  }
}
