import { Controller } from "@hotwired/stimulus"

// Copies text (carried in a value, e.g. the Markdown export or an invitation link) to the clipboard.
export default class extends Controller {
  static targets = ["button"]
  static values = { text: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
      this.#flash("Copied")
    } catch {
      this.#flash("Copy failed")
    }
  }

  #flash(message) {
    const original = (this.buttonTarget.dataset.original ??= this.buttonTarget.innerHTML)
    this.buttonTarget.textContent = message
    setTimeout(() => (this.buttonTarget.innerHTML = original), 1600)
  }
}
