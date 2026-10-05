import { Controller } from "@hotwired/stimulus"

// Copies text to the clipboard: either carried in a value (an invitation link) or fetched
// from a URL when clicked (the Markdown export).
export default class extends Controller {
  static targets = ["button"]
  static values = { text: String, url: String }

  async copy() {
    try {
      if (this.hasUrlValue) {
        // Hand the clipboard a promise so Safari still counts the write as part of the click.
        const blob = this.#fetchText().then((text) => new Blob([text], { type: "text/plain" }))
        await navigator.clipboard.write([new ClipboardItem({ "text/plain": blob })])
      } else {
        await navigator.clipboard.writeText(this.textValue)
      }
      this.#flash("Copied")
    } catch {
      this.#flash("Copy failed")
    }
  }

  select(event) {
    event.target.select()
  }

  // A redirect (e.g. to sign in) is a failure, not text to copy.
  async #fetchText() {
    const response = await fetch(this.urlValue, { headers: { Accept: "text/markdown" }, redirect: "manual" })
    if (!response.ok) throw new Error(`Copy fetch failed: ${response.status}`)
    return response.text()
  }

  #flash(message) {
    const original = (this.buttonTarget.dataset.original ??= this.buttonTarget.innerHTML)
    this.buttonTarget.textContent = message
    setTimeout(() => (this.buttonTarget.innerHTML = original), 1600)
  }
}
