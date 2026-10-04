import { Controller } from "@hotwired/stimulus"

// Keeps a title on one line: when it overflows, drop the secondary <small> text first (the title itself then ellipsizes).
export default class extends Controller {
  connect() {
    this.observer = new ResizeObserver(() => this.fit())
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer.disconnect()
  }

  fit() {
    if (!this.element.clientWidth) return
    this.element.classList.remove("tight")
    this.element.classList.toggle("tight", this.element.scrollWidth > this.element.clientWidth)
  }
}
