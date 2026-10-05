import { Controller } from "@hotwired/stimulus"

// The note panel: docked down the right on desktop, a bottom sheet on phones whose handle shows the note's first line.
export default class extends Controller {
  static targets = ["label", "handle", "preview"]

  // On phones the on-screen keyboard covers the bottom of the page without resizing it. Track the
  // visible area so the sheet can sit above the keyboard and shrink to fit (--kb, --vvh in the CSS).
  connect() {
    this.#trackHeader()
    this.viewport = window.visualViewport
    if (!this.viewport) return
    this.fit = () => this.#fit()
    this.viewport.addEventListener("resize", this.fit)
    this.viewport.addEventListener("scroll", this.fit)
    this.fit()
  }

  disconnect() {
    this.headerObserver?.disconnect()
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
    this.labelTarget.textContent = open ? "▾" : "▴"
    this.handleTarget.setAttribute("aria-expanded", open)
  }

  // The editor reports its text as it loads and changes (note:text).
  preview({ detail: { text } }) {
    this.previewTarget.textContent = text || "Write a note"
    this.previewTarget.classList.toggle("empty", !text)
  }

  // The passage's reference row sticks just below the sticky focus band, whose height varies (the focus can
  // wrap), so publish it as --top-h on the document.
  #trackHeader() {
    const header = document.querySelector("[data-reader-top]")
    if (!header) return
    const set = () => document.documentElement.style.setProperty("--top-h", `${header.offsetHeight}px`)
    this.headerObserver = new ResizeObserver(set)
    this.headerObserver.observe(header)
    set()
  }

  #fit() {
    const { height, offsetTop, scale } = this.viewport
    // Pinch-zoom also changes the visual viewport; only the keyboard should move the sheet.
    const keyboard = scale > 1.01 ? 0 : Math.max(0, window.innerHeight - height - offsetTop)
    this.element.style.setProperty("--kb", `${Math.round(keyboard)}px`)
    this.element.style.setProperty("--vvh", `${Math.round(height)}px`)
  }
}
