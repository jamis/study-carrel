import { Controller } from "@hotwired/stimulus"

// Shows or hides a panel in place, such as the extra Random choices inside the ⋯ menu.
export default class extends Controller {
  static targets = ["button", "panel"]

  toggle() {
    const open = this.panelTarget.hidden
    this.panelTarget.hidden = !open
    this.buttonTarget.setAttribute("aria-expanded", open)
  }
}
