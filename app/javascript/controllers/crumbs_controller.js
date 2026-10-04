import { Controller } from "@hotwired/stimulus"

// Breadcrumbs that fit on one line: the first and last always stay; when the trail is too wide the middle
// steps drop out (the one nearest the root first) and a "…" takes their place. The last step ellipsizes
// as a final resort.
export default class extends Controller {
  static targets = ["item"]

  connect() {
    this.list = this.element.querySelector("ol")
    this.more = this.element.querySelector(".crumb-more")
    this.observer = new ResizeObserver(() => this.fit())
    this.observer.observe(this.element)
    document.fonts?.ready.then(() => this.fit())
  }

  disconnect() {
    this.observer.disconnect()
  }

  fit() {
    if (!this.element.clientWidth) return
    const items = this.itemTargets
    items.forEach(i => i.hidden = false)
    this.more.hidden = true
    this.list.classList.add("measuring")
    for (let n = 1; n < items.length - 1 && this.list.scrollWidth > this.list.clientWidth; n++) {
      this.more.hidden = false
      items[n].hidden = true
    }
    this.list.classList.remove("measuring")
    this.more.title = items.filter(i => i.hidden).map(i => i.textContent.trim()).join(" › ")
  }
}
