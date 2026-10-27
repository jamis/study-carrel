import { Controller } from "@hotwired/stimulus"

// The rail's labels show once one of its icons is pointed at (.labels, styled in CSS), and stay while the pointer is
// anywhere on the rail, so crossing the gaps between icons doesn't flicker them shut; the rail's blank stretch and
// edges don't open them, so a tablet swipe that starts there scrolls without widening it. Touch lifts close them.
// Each time they open, Continue reading's destination drops its work title if the whole reference won't fit under the
// label, as the note panel's does (lectio_controller#fitRef).
export default class extends Controller {
  static targets = ["dest"]

  point(event) {
    if (this.element.classList.contains("labels") || !event.target.closest(".rail-btn")) return
    this.element.classList.add("labels")
    this.fit()
  }

  leave() {
    this.element.classList.remove("labels")
  }

  lift(event) {
    if (event.pointerType !== "mouse") this.leave()
  }

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
