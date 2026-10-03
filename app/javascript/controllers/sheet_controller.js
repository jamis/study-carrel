import { Controller } from "@hotwired/stimulus"

// The notes panel: a side card on desktop, a bottom sheet on phones.
export default class extends Controller {
  static targets = ["label", "handle"]

  // On phones the on-screen keyboard covers the bottom of the page without resizing it. Track the
  // visible area so the sheet can sit above the keyboard and shrink to fit (--kb, --vvh in the CSS).
  connect() {
    this.viewport = window.visualViewport
    if (!this.viewport) return
    this.fit = () => this.#fit()
    this.viewport.addEventListener("resize", this.fit)
    this.viewport.addEventListener("scroll", this.fit)
    this.fit()
  }

  disconnect() {
    this.viewport?.removeEventListener("resize", this.fit)
    this.viewport?.removeEventListener("scroll", this.fit)
  }

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

  #fit() {
    const { height, offsetTop, scale } = this.viewport
    // Pinch-zoom also changes the visual viewport; only the keyboard should move the sheet.
    const keyboard = scale > 1.01 ? 0 : Math.max(0, window.innerHeight - height - offsetTop)
    this.element.style.setProperty("--kb", `${Math.round(keyboard)}px`)
    this.element.style.setProperty("--vvh", `${Math.round(height)}px`)
  }
}
