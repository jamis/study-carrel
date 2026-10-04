import { Controller } from "@hotwired/stimulus"

// Recent places, in a dropdown opened by the menu controller (same element). Fetches a fresh list each time it
// opens; "h" opens it from the keyboard, and Up / Down move through the rows.
export default class extends Controller {
  static targets = ["button", "panel", "list"]
  static values = { url: String }

  async refresh() {
    if (!this.panelTarget.classList.contains("open")) return
    const response = await fetch(this.urlValue, { headers: { Accept: "text/html" } })
    if (!response.ok || !this.panelTarget.classList.contains("open")) return
    this.listTarget.innerHTML = await response.text()
    if (this.focusFirst) this.rows[0]?.focus()
    this.focusFirst = false
  }

  key(event) {
    if (event.key !== "h" || event.metaKey || event.ctrlKey || event.altKey) return
    if (event.target.closest("input, textarea, select, [contenteditable]")) return
    this.focusFirst = true
    this.buttonTarget.click()
  }

  arrow(event) {
    if (event.key !== "ArrowDown" && event.key !== "ArrowUp") return
    event.preventDefault()
    const rows = this.rows
    const at = rows.indexOf(document.activeElement)
    rows[(at + (event.key === "ArrowDown" ? 1 : -1) + rows.length) % rows.length]?.focus()
  }

  get rows() { return [...this.listTarget.querySelectorAll("a")] }
}
