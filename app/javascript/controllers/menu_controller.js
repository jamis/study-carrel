import { Controller } from "@hotwired/stimulus"

// A small disclosure menu: the button opens a panel, and an outside tap, Escape or
// choosing something closes it. (At wider widths CSS shows the panel's items inline.)
export default class extends Controller {
  static targets = ["button", "panel"]

  toggle() { this.open ? this.close() : this.show() }

  show() {
    this.panelTarget.classList.add("open")
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.panelTarget.classList.remove("open")
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  escape() {
    if (!this.open) return
    this.close()
    this.buttonTarget.focus()
  }

  away(event) {
    if (this.open && !this.element.contains(event.target)) this.close()
  }

  get open() { return this.panelTarget.classList.contains("open") }
}
