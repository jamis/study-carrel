import { Controller } from "@hotwired/stimulus"
import { keyboardOpener, giveBackFocus } from "lib/focus"

// A small disclosure menu: the button opens a panel, and an outside tap, Escape or
// choosing something closes it. (At wider widths CSS shows the panel's items inline.)
export default class extends Controller {
  static targets = ["button", "panel"]

  toggle(event) {
    if (this.open) return this.close()
    this.opener = keyboardOpener(event)
    this.show()
  }

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
    giveBackFocus(this.opener, this.panelTarget)
  }

  away(event) {
    if (this.open && !this.element.contains(event.target)) this.close()
  }

  get open() { return this.panelTarget.classList.contains("open") }
}
