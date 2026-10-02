import { Controller } from "@hotwired/stimulus"

// Long quoted passages are clamped; this reveals or re-clamps the full text.
export default class extends Controller {
  static targets = ["text", "button"]

  toggle() {
    const clamped = this.textTarget.classList.toggle("clamped")
    this.buttonTarget.textContent = clamped ? "Show full passage" : "Show less"
    this.buttonTarget.setAttribute("aria-expanded", !clamped)
  }
}
