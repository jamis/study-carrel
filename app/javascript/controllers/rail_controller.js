import { Controller } from "@hotwired/stimulus"

// The rail's labels show while it's pointed at (CSS); each time they open, Continue reading's destination drops its
// work title if the whole reference won't fit under the label, as the note panel's does (lectio_controller#fitRef).
export default class extends Controller {
  static targets = ["dest"]

  fit() {
    if (!this.hasDestTarget) return
    requestAnimationFrame(() => {
      const ref = this.destTarget
      if (!ref.clientWidth) return
      ref.classList.remove("tight")
      const needed = [...ref.children].reduce((sum, c) => sum + (c.classList.contains("ref-section") ? c.scrollWidth : c.offsetWidth), 0)
      ref.classList.toggle("tight", needed > ref.clientWidth)
    })
  }
}
