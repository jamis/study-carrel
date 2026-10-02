import { Controller } from "@hotwired/stimulus"

// Copies the Markdown export (carried in a value) to the clipboard.
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
    const original = "Copy Markdown"
    this.buttonTarget.textContent = message
    setTimeout(() => (this.buttonTarget.textContent = original), 1600)
  }
}
